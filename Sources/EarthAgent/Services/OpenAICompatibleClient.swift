import Foundation

enum AIClientError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case providerError(String)
    case emptyReply

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "The provider Base URL is not valid."
        case .invalidResponse:
            return "The provider returned an invalid response."
        case .providerError(let message):
            return message
        case .emptyReply:
            return "The provider returned an empty reply."
        }
    }
}

final class OpenAICompatibleClient {
    private let maxInlineImageBytes = 4_000_000
    private let configuration: ProviderConfiguration
    private let apiKey: String

    init(configuration: ProviderConfiguration, apiKey: String) {
        self.configuration = configuration
        self.apiKey = apiKey
    }

    func send(messages: [ChatMessage]) async throws -> String {
        var request = try makeRequest()
        let payload = try makePayload(messages: messages, includeImages: true, stream: nil)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode),
           hasImageAttachments(messages),
           shouldRetryTextOnly(statusCode: http.statusCode, data: data) {
            var retryRequest = request
            let retryPayload = try makePayload(messages: messages, includeImages: false, stream: nil)
            retryRequest.httpBody = try JSONEncoder().encode(retryPayload)
            return try await decodeResponse(from: URLSession.shared.data(for: retryRequest))
        }
        return try decodeResponse(from: (data, response))
    }

    func stream(
        messages: [ChatMessage],
        onToken: @escaping (String) async -> Void
    ) async throws -> String {
        do {
            return try await stream(messages: messages, includeImages: true, onToken: onToken)
        } catch {
            guard hasImageAttachments(messages) else { throw error }
            return try await stream(messages: messages, includeImages: false, onToken: onToken)
        }
    }

    private func stream(
        messages: [ChatMessage],
        includeImages: Bool,
        onToken: @escaping (String) async -> Void
    ) async throws -> String {
        var request = try makeRequest()
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(makePayload(messages: messages, includeImages: includeImages, stream: true))

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let body = try await readLimitedBody(from: bytes, limit: 1_200)
            let providerError = (try? JSONDecoder().decode(ProviderErrorResponse.self, from: Data(body.utf8)).error.message)
            throw AIClientError.providerError(redacted(providerError ?? "Provider stream failed with HTTP \(http.statusCode)."))
        }

        var fullText = ""
        var currentEvent = ""
        for try await line in bytes.lines {
            if line.isEmpty {
                if let token = try StreamingChatParser.token(from: currentEvent) {
                    fullText += token
                    await onToken(token)
                }
                currentEvent = ""
            } else {
                currentEvent += line + "\n"
            }
        }

        if let token = try StreamingChatParser.token(from: currentEvent) {
            fullText += token
            await onToken(token)
        }

        let reply = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reply.isEmpty else { throw AIClientError.emptyReply }
        return reply
    }

    private func makeRequest() throws -> URLRequest {
        guard let baseURL = URL(string: normalizedBaseURL(configuration.baseURL)) else {
            throw AIClientError.invalidBaseURL
        }
        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        return request
    }

    private func makePayload(messages: [ChatMessage], includeImages: Bool, stream: Bool?) throws -> ChatCompletionRequest {
        ChatCompletionRequest(
            model: configuration.modelName,
            messages: try messages.suffix(24).map { try makeRequestMessage(from: $0, includeImages: includeImages) },
            temperature: 0.7,
            stream: stream
        )
    }

    private func makeRequestMessage(from message: ChatMessage, includeImages: Bool) throws -> ChatCompletionRequest.Message {
        let imageParts = includeImages ? try imageContentParts(from: message.attachments) : []
        guard !imageParts.isEmpty else {
            return .init(role: message.role.rawValue, content: .text(message.content))
        }

        var parts = [ChatCompletionRequest.ContentPart.text(message.content)]
        parts.append(contentsOf: imageParts)
        return .init(role: message.role.rawValue, content: .parts(parts))
    }

    private func imageContentParts(from attachments: [ChatAttachment]) throws -> [ChatCompletionRequest.ContentPart] {
        try attachments
            .filter { $0.kind == .photo && $0.byteCount > 0 && $0.byteCount <= Int64(maxInlineImageBytes) }
            .prefix(3)
            .compactMap { attachment in
                guard let mimeType = mimeType(for: attachment.url) else { return nil }
                let data = try Data(contentsOf: attachment.url)
                let url = "data:\(mimeType);base64,\(data.base64EncodedString())"
                return .imageURL(url)
            }
    }

    private func hasImageAttachments(_ messages: [ChatMessage]) -> Bool {
        messages.contains { message in
            message.attachments.contains { $0.kind == .photo }
        }
    }

    private func shouldRetryTextOnly(statusCode: Int, data: Data) -> Bool {
        guard [400, 404, 415, 422].contains(statusCode) else { return false }
        let providerError = (try? JSONDecoder().decode(ProviderErrorResponse.self, from: data).error.message) ?? ""
        let lowered = providerError.lowercased()
        return lowered.contains("image") ||
            lowered.contains("content") ||
            lowered.contains("multimodal") ||
            lowered.contains("schema") ||
            lowered.contains("unsupported") ||
            lowered.contains("invalid")
    }

    private func decodeResponse(from result: (Data, URLResponse)) throws -> String {
        let (data, response) = result
        guard let http = response as? HTTPURLResponse else {
            throw AIClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let providerError = (try? JSONDecoder().decode(ProviderErrorResponse.self, from: data).error.message)
            throw AIClientError.providerError(redacted(providerError ?? "Provider request failed with HTTP \(http.statusCode)."))
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let reply = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines), !reply.isEmpty else {
            throw AIClientError.emptyReply
        }
        return reply
    }

    private func readLimitedBody(from bytes: URLSession.AsyncBytes, limit: Int) async throws -> String {
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            if data.count >= limit { break }
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func mimeType(for url: URL) -> String? {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "heic":
            return "image/heic"
        default:
            return nil
        }
    }

    private func normalizedBaseURL(_ value: String) -> String {
        var clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while clean.hasSuffix("/") {
            clean.removeLast()
        }
        return clean
    }

    private func redacted(_ message: String) -> String {
        message.replacingOccurrences(of: apiKey, with: "[redacted]")
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let stream: Bool?

    struct Message: Encodable {
        let role: String
        let content: Content
    }

    enum Content: Encodable {
        case text(String)
        case parts([ContentPart])

        func encode(to encoder: Encoder) throws {
            switch self {
            case .text(let text):
                var container = encoder.singleValueContainer()
                try container.encode(text)
            case .parts(let parts):
                var container = encoder.singleValueContainer()
                try container.encode(parts)
            }
        }
    }

    enum ContentPart: Encodable {
        case text(String)
        case imageURL(String)

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageURL = "image_url"
        }

        enum ImageURLKeys: String, CodingKey {
            case url
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .imageURL(let url):
                try container.encode("image_url", forKey: .type)
                var imageURL = container.nestedContainer(keyedBy: ImageURLKeys.self, forKey: .imageURL)
                try imageURL.encode(url, forKey: .url)
            }
        }
    }
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

private struct ProviderErrorResponse: Decodable {
    let error: ProviderError

    struct ProviderError: Decodable {
        let message: String
    }
}
