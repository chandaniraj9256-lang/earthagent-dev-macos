import Foundation

enum SafetyMode: String, Codable, CaseIterable, Identifiable {
    case chatOnly = "Chat only"
    case draftOnly = "Draft only"
    case askBeforeActions = "Ask before actions"
    case autopilotSafe = "Autopilot for safe actions"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .chatOnly:
            return "Earth only answers. It will not open apps or websites."
        case .draftOnly:
            return "Earth can draft content, but external actions stay locked."
        case .askBeforeActions:
            return "Earth asks before opening apps, websites, typing, or clicking."
        case .autopilotSafe:
            return "Earth may open apps and websites, but still asks before sensitive actions."
        }
    }
}
