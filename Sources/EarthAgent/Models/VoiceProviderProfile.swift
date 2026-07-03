import Foundation

struct VoiceProviderProfile: Identifiable, Hashable {
    enum Status: String {
        case working = "Working"
        case planned = "Planned"
    }

    let id: String
    let name: String
    let baseURL: String
    let defaultModel: String
    let defaultVoice: String
    let models: [String]
    let voices: [String]
    let notes: String
    let status: Status
}
