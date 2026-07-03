import Foundation

final class SessionArchiveStore {
    private let defaultsKey = "earth-agent-session-archive-v1"
    private let maxEntries = 600

    func load() -> [SessionArchiveEntry] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([SessionArchiveEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    func append(_ entry: SessionArchiveEntry, to entries: [SessionArchiveEntry]) -> [SessionArchiveEntry] {
        let next = ([entry] + entries).prefix(maxEntries)
        let compact = Array(next)
        save(compact)
        return compact
    }

    func save(_ entries: [SessionArchiveEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    func search(_ query: String, in entries: [SessionArchiveEntry]) -> [SessionSearchResult] {
        let terms = query
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .map(String.init)
            .filter { $0.count >= 2 }
        guard !terms.isEmpty else { return [] }

        return entries.compactMap { entry in
            let haystack = (entry.text + " " + entry.attachmentNames.joined(separator: " ")).lowercased()
            let score = terms.reduce(0) { partial, term in
                haystack.contains(term) ? partial + 1 : partial
            }
            guard score > 0 else { return nil }
            return SessionSearchResult(entry: entry, snippet: makeSnippet(entry.text, terms: terms))
        }
        .prefix(20)
        .map { $0 }
    }

    private func makeSnippet(_ text: String, terms: [String]) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
        guard clean.count > 180 else { return clean }
        let lowered = clean.lowercased()
        if let range = terms.compactMap({ lowered.range(of: $0) }).first {
            let start = clean.index(range.lowerBound, offsetBy: -60, limitedBy: clean.startIndex) ?? clean.startIndex
            let end = clean.index(range.upperBound, offsetBy: 120, limitedBy: clean.endIndex) ?? clean.endIndex
            return String(clean[start..<end])
        }
        return String(clean.prefix(180)) + "..."
    }
}
