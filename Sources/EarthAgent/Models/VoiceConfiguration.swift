import Foundation

struct VoiceConfiguration: Codable, Equatable {
    var providerID: String
    var providerName: String
    var modelName: String
    var voiceID: String
    var baseURL: String

    static let macOS = VoiceConfiguration(
        providerID: "macos",
        providerName: "macOS System Voice",
        modelName: "system",
        voiceID: "system-default",
        baseURL: ""
    )
}
