import Foundation

final class MemoryStore {
    private let defaultsKey = "earth-agent-memory"

    func load() -> [UserMemoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return [] }
        return (try? JSONDecoder().decode([UserMemoryEntry].self, from: data)) ?? []
    }

    func save(_ entries: [UserMemoryEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
