import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    let content: String
    let createdAt: Date
    let attachments: [ChatAttachment]

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        createdAt: Date = Date(),
        attachments: [ChatAttachment] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.attachments = attachments
    }
}
