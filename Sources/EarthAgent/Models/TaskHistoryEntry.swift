import Foundation

struct TaskHistoryEntry: Identifiable, Codable, Equatable {
    enum State: String, Codable {
        case planned = "Planned"
        case waitingForConfirmation = "Waiting"
        case running = "Running"
        case completed = "Completed"
        case failed = "Failed"
        case paused = "Paused"
        case cancelled = "Cancelled"
    }

    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let title: String
    let userText: String
    let category: String
    let risk: String
    let expectedResult: String
    let requiresConfirmation: Bool
    var state: State
    var summary: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        title: String,
        userText: String,
        category: String,
        risk: String,
        expectedResult: String,
        requiresConfirmation: Bool,
        state: State,
        summary: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.userText = userText
        self.category = category
        self.risk = risk
        self.expectedResult = expectedResult
        self.requiresConfirmation = requiresConfirmation
        self.state = state
        self.summary = summary
    }
}
