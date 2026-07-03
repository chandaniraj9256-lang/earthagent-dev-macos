import Foundation

struct LaunchReadinessItem: Identifiable, Equatable {
    enum Category: String {
        case ai = "AI"
        case voice = "Voice"
        case permissions = "Permissions"
        case safety = "Safety"
        case background = "Background"
        case product = "Product"
    }

    let id: String
    let title: String
    let detail: String
    let state: ReadinessItem.State
    let category: Category
}

struct LaunchReadinessSummary: Equatable {
    let score: Int
    let label: String
    let detail: String
    let items: [LaunchReadinessItem]

    var readyCount: Int {
        items.filter { $0.state == .ready }.count
    }

    var totalCount: Int {
        items.count
    }
}
