import Foundation

final class PromptQueueStore {
    private let defaultsKey = "earth-agent-prompt-queue-v1"

    func load() -> [PromptQueueEntry] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([PromptQueueEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    func save(_ entries: [PromptQueueEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
