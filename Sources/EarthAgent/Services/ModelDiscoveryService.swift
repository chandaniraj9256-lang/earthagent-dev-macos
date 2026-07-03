import Foundation

enum ModelDiscoveryError: LocalizedError {
    case invalidURL
    case providerError(String)
    case emptyList

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provider model endpoint is not valid."
        case .providerError(let message):
            return message
        case .emptyList:
            return "The provider did not return any models."
        }
    }
}

final class ModelDiscoveryService {
    func fetchModels(baseURL: String, apiKey: String?) async throws -> [String] {
        guard let base = URL(string: normalizedBaseURL(baseURL)) else {
            throw ModelDiscoveryError.invalidURL
        }

        var request = URLRequest(url: base.appendingPathComponent("models"))
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ModelDiscoveryError.providerError("The provider returned an invalid response.")
        }
        guard (200...299).contains(http.statusCode) else {
            let providerMessage = (try? JSONDecoder().decode(ProviderErrorResponse.self, from: data).error.message)
            throw ModelDiscoveryError.providerError(providerMessage ?? "Model refresh failed with HTTP \(http.statusCode).")
        }

        let ids = try modelIDs(from: data)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        guard !ids.isEmpty else { throw ModelDiscoveryError.emptyList }
        return ids
    }

    private func normalizedBaseURL(_ value: String) -> String {
        var clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while clean.hasSuffix("/") {
            clean.removeLast()
        }
        return clean
    }

    private func modelIDs(from data: Data) throws -> [String] {
        let object = try JSONSerialization.jsonObject(with: data)
        let rawItems: [Any]
        if let dictionary = object as? [String: Any],
           let dataItems = dictionary["data"] as? [Any] {
            rawItems = dataItems
        } else if let dictionary = object as? [String: Any],
                  let modelItems = dictionary["models"] as? [Any] {
            rawItems = modelItems
        } else if let array = object as? [Any] {
            rawItems = array
        } else {
            rawItems = []
        }

        return rawItems.compactMap { item in
            if let value = item as? String {
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let dictionary = item as? [String: Any] {
                let value = dictionary["id"] ?? dictionary["name"] ?? dictionary["model"]
                return (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }
        .filter { !$0.isEmpty }
    }
}

private struct ProviderErrorResponse: Decodable {
    let error: ProviderError

    struct ProviderError: Decodable {
        let message: String
    }
}
