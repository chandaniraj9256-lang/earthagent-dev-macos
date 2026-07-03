import Foundation

enum StreamingChatParser {
    static func token(from event: String) throws -> String? {
        let payloads = event
            .components(separatedBy: .newlines)
            .filter { $0.hasPrefix("data:") }
            .map { line in
                String(line.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            }

        var combined = ""
        for payload in payloads {
            guard !payload.isEmpty, payload != "[DONE]" else { continue }
            guard let data = payload.data(using: .utf8) else { continue }
            let decoded = try JSONDecoder().decode(ChatCompletionStreamResponse.self, from: data)
            if let content = decoded.choices.first?.delta.content {
                combined += content
            }
        }

        return combined.isEmpty ? nil : combined
    }
}

private struct ChatCompletionStreamResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let delta: Delta
    }

    struct Delta: Decodable {
        let content: String?
    }
}
