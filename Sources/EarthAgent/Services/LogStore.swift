import Foundation

final class LogStore {
    private var url: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("EarthAgent", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("action-log.json")
    }

    func load() -> [LocalLogEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([LocalLogEntry].self, from: data)) ?? []
    }

    func save(_ entries: [LocalLogEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
