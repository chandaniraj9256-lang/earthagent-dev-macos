import Foundation

struct ChatAttachment: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case photo = "Photo"
        case video = "Video"
        case document = "Document"
        case file = "File"
    }

    let id: UUID
    let url: URL
    let name: String
    let kind: Kind
    let byteCount: Int64
    let textPreview: String?

    init(
        id: UUID = UUID(),
        url: URL,
        name: String,
        kind: Kind,
        byteCount: Int64,
        textPreview: String? = nil
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.kind = kind
        self.byteCount = byteCount
        self.textPreview = textPreview
    }

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }
}
