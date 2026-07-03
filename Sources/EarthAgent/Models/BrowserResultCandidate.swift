import Foundation

struct BrowserResultCandidate: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case searchResult = "Search result"
        case website = "Website"
        case document = "Document"
        case media = "Media"
        case pageControl = "Page control"
    }

    let id: Int
    let elementID: Int
    let title: String
    let kind: Kind
    let canOpen: Bool

    var summary: String {
        "#\(id) \(kind.rawValue): \(title)"
    }
}
