import Foundation

struct ReadinessItem: Identifiable, Equatable {
    enum State: Equatable {
        case ready
        case warning
        case actionNeeded
    }

    let id: String
    let title: String
    let detail: String
    let state: State
}
