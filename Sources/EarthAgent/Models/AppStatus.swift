import Foundation

enum AppStatus: String, CaseIterable, Identifiable {
    case idle = "Ready"
    case listening = "Listening"
    case thinking = "Thinking"
    case working = "Working"
    case waitingForConfirmation = "Waiting for confirmation"
    case completed = "Task completed"
    case failed = "Task failed"
    case paused = "Paused"
    case stopped = "Stopped"

    var id: String { rawValue }
}
