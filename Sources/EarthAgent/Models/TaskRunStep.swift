import Foundation

struct TaskRunStep: Identifiable, Equatable {
    enum State: String, Equatable {
        case pending = "Pending"
        case running = "Running"
        case completed = "Done"
        case blocked = "Blocked"
        case failed = "Failed"
    }

    let id = UUID()
    let title: String
    var detail: String
    var state: State
}
