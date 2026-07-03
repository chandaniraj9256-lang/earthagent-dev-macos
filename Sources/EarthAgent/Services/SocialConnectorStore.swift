import Foundation

final class SocialConnectorStore {
    private let defaultsKey = "earth-agent-social-connectors-v1"
    private let keychain: KeychainService

    init(keychain: KeychainService) {
        self.keychain = keychain
    }

    func load() -> [SocialConnectorProfile] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([SocialConnectorProfile].self, from: data) else {
            return SocialConnectorProfile.defaults
        }
        return mergeSaved(decoded)
    }

    func save(_ connectors: [SocialConnectorProfile]) {
        guard let data = try? JSONEncoder().encode(connectors) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    func saveSecret(_ secret: String, for connector: SocialConnectorProfile) throws {
        try keychain.save(secret, account: "social-\(connector.id)")
    }

    func hasSecret(for connector: SocialConnectorProfile) -> Bool {
        keychain.exists(account: "social-\(connector.id)")
    }

    private func mergeSaved(_ saved: [SocialConnectorProfile]) -> [SocialConnectorProfile] {
        let savedByID = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
        var merged = SocialConnectorProfile.defaults.map { fallback in
            savedByID[fallback.id] ?? fallback
        }
        let custom = saved.filter { savedItem in
            !SocialConnectorProfile.defaults.contains(where: { $0.id == savedItem.id })
        }
        merged.append(contentsOf: custom)
        return merged
    }
}

final class SocialConnectorService {
    func validationStatus(for connector: SocialConnectorProfile) -> SocialConnectorProfile.Status {
        if connector.status == .planned { return .planned }
        let hasWebhook = URL(string: connector.webhookURL.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
        let hasDestination = !connector.allowedDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (connector.botTokenSaved || hasWebhook) && hasDestination ? .connected : .needsSetup
    }

    func statusReport(connectors: [SocialConnectorProfile]) -> String {
        let enabled = connectors.filter(\.isEnabled)
        if enabled.isEmpty {
            return "No social connector is enabled. Telegram, WhatsApp, Slack, Discord, and Email stay off until you configure and enable them."
        }
        return enabled.map { connector in
            "- \(connector.displayName): \(connector.status.rawValue), destination \(connector.allowedDestination.isEmpty ? "not set" : connector.allowedDestination)"
        }.joined(separator: "\n")
    }
}
