import Foundation

struct LocalLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let message: String

    init(id: UUID = UUID(), createdAt: Date = Date(), message: String) {
        self.id = id
        self.createdAt = createdAt
        self.message = message
    }
}
