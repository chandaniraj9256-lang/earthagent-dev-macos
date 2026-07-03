import Foundation

final class VoiceTurnSettingsStore {
    private let defaultsKey = "earth-agent-voice-turn-settings"

    func load() -> VoiceTurnSettings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode(VoiceTurnSettings.self, from: data) else {
            return .standard
        }
        return decoded.normalized
    }

    func save(_ settings: VoiceTurnSettings) {
        let normalized = settings.normalized
        guard let data = try? JSONEncoder().encode(normalized) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
