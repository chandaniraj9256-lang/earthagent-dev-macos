import Foundation

final class ProviderSettingsStore {
    private let keychain: KeychainService
    private let apiKeyAccount = "provider-api-key"
    private let defaultsKey = "provider-configuration"

    init(keychain: KeychainService) {
        self.keychain = keychain
    }

    var hasAPIKey: Bool {
        keychain.exists(account: apiKeyAccount)
    }

    func loadConfiguration() -> ProviderConfiguration {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let config = try? JSONDecoder().decode(ProviderConfiguration.self, from: data)
        else {
            return .empty
        }
        return config
    }

    func saveConfiguration(_ configuration: ProviderConfiguration) {
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
