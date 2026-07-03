import Foundation

struct UserMemoryEntry: Identifiable, Codable, Equatable {
    enum Category: String, CaseIterable, Codable, Equatable, Identifiable {
        case preferences = "Preferences"
        case writingStyle = "Writing style"
        case workContext = "Work context"
        case projectDetails = "Project details"
        case appBehavior = "App behavior"

        var id: String { rawValue }
    }

    let id: UUID
    let createdAt: Date
    var text: String
    var category: Category

    init(id: UUID = UUID(), createdAt: Date = Date(), text: String, category: Category = .preferences) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.category = category
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case text
        case category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        text = try container.decode(String.self, forKey: .text)
        if let rawCategory = try container.decodeIfPresent(String.self, forKey: .category) {
            category = Category(rawValue: rawCategory) ?? .preferences
        } else {
            category = .preferences
        }
    }
}
