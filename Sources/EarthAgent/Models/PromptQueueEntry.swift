import Foundation

struct PromptQueueEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var attachments: [ChatAttachment]
    let queuedAt: Date

    init(id: UUID = UUID(), text: String, attachments: [ChatAttachment] = [], queuedAt: Date = Date()) {
        self.id = id
        self.text = text
        self.attachments = attachments
        self.queuedAt = queuedAt
    }
}
