import Foundation

final class VoiceSettingsStore {
    private let keychain: KeychainService
    private let apiKeyAccount = "voice-api-key"
    private let defaultsKey = "voice-configuration"

    init(keychain: KeychainService) {
        self.keychain = keychain
    }

    var hasAPIKey: Bool {
        keychain.exists(account: apiKeyAccount)
    }

    func loadConfiguration() -> VoiceConfiguration {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let config = try? JSONDecoder().decode(VoiceConfiguration.self, from: data)
        else {
            return .macOS
        }
        return config
    }

    func saveConfiguration(_ configuration: VoiceConfiguration) {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    func saveAPIKey(_ apiKey: String) throws {
        try keychain.save(apiKey, account: apiKeyAccount)
    }

    func loadAPIKey() throws -> String {
        try keychain.read(account: apiKeyAccount)
    }
}
