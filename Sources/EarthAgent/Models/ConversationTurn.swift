import Foundation

struct ConversationTurn: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String
    let createdAt: Date
    let wasInterrupted: Bool

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        createdAt: Date = Date(),
        wasInterrupted: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.wasInterrupted = wasInterrupted
    }
}
