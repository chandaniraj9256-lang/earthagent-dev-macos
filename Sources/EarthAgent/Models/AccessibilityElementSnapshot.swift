import Foundation

struct AccessibilityElementSnapshot: Identifiable, Equatable {
    let id: Int
    let role: String
    let title: String
    let value: String
    let frameDescription: String
    let canPress: Bool

    var displayName: String {
        let name = title.isEmpty ? value : title
        return name.isEmpty ? role : name
    }

    var summary: String {
        let action = canPress ? "clickable" : "visible"
        return "#\(id) \(role): \(displayName) (\(action))"
    }
}
