import Foundation

struct SessionArchiveEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let role: ChatMessage.Role
    let text: String
    let attachmentNames: [String]

    init(id: UUID = UUID(), createdAt: Date = Date(), role: ChatMessage.Role, text: String, attachmentNames: [String] = []) {
        self.id = id
        self.createdAt = createdAt
        self.role = role
        self.text = text
        self.attachmentNames = attachmentNames
    }
}

struct SessionSearchResult: Identifiable, Equatable {
    let id = UUID()
    let entry: SessionArchiveEntry
    let snippet: String
}
