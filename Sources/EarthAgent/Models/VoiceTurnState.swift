import Foundation

enum VoiceTurnState: String, Equatable {
    case idle = "Voice ready"
    case listening = "Listening"
    case processing = "Preparing reply"
    case speaking = "Speaking"
    case interrupted = "Interrupted"
    case paused = "Paused"
    case stopped = "Stopped"
    case failed = "Voice failed"

    var shortLabel: String {
        switch self {
        case .idle: "Voice ready"
        case .listening: "Listening..."
        case .processing: "Thinking..."
        case .speaking: "Speaking..."
        case .interrupted: "Interrupted"
        case .paused: "Paused"
        case .stopped: "Stopped"
        case .failed: "Voice issue"
        }
    }
}
