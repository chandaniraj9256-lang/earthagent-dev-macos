import Foundation

final class TaskRunnerService {
    func makeSteps(from task: AgentTask) -> [TaskRunStep] {
        task.steps.map {
            TaskRunStep(title: $0, detail: "Waiting", state: .pending)
        }
    }
}
