import Foundation

struct SavedNoteResult {
    let directory: URL
    let file: URL
}

struct SavedNoteSummary: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let file: URL
    let modifiedAt: Date

    var displayName: String {
        file.deletingPathExtension().lastPathComponent
    }
}

final class NoteWriterService {
    private let rootDirectory: URL

    init(rootDirectory: URL? = nil) {
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents", isDirectory: true)
            self.rootDirectory = documents
                .appendingPathComponent("Earth Agent", isDirectory: true)
                .appendingPathComponent("Notes", isDirectory: true)
        }
    }

    func save(title: String, body: String, createdAt: Date = Date()) throws -> SavedNoteResult {
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBody.isEmpty else {
            throw CocoaError(.fileWriteUnknown)
        }

        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let file = rootDirectory.appendingPathComponent("\(formatter.string(from: createdAt))-\(slug(from: title)).md")
        let markdown = """
        # \(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Earth Agent Note" : title.trimmingCharacters(in: .whitespacesAndNewlines))

        Saved from Earth Agent on \(createdAt.formatted(date: .abbreviated, time: .shortened)).

        ---

        \(cleanBody)
        """
        try markdown.write(to: file, atomically: true, encoding: .utf8)
        return SavedNoteResult(directory: rootDirectory, file: file)
    }

    func ensureNotesDirectory() throws -> URL {
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        return rootDirectory
    }

    func listNotes(limit: Int = 8) throws -> [SavedNoteSummary] {
        let directory = try ensureNotesDirectory()
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        return try files
            .filter { $0.pathExtension.lowercased() == "md" }
            .map { file in
                let values = try file.resourceValues(forKeys: [.contentModificationDateKey])
                return SavedNoteSummary(
                    title: title(from: file),
                    file: file,
                    modifiedAt: values.contentModificationDate ?? .distantPast
                )
            }
            .sorted { $0.modifiedAt > $1.modifiedAt }
            .prefix(limit)
            .map { $0 }
    }

    func read(_ note: SavedNoteSummary, limit: Int = 12_000) throws -> String {
        let text = try String(contentsOf: note.file, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        if text.count <= limit {
            return text
        }
        return String(text.prefix(limit)) + "\n\n[Note was truncated for chat.]"
    }

    private func slug(from title: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let lowered = title.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let filtered = String(lowered.unicodeScalars.filter { allowed.contains($0) })
        return filtered.isEmpty ? "earth-agent-note" : String(filtered.prefix(48))
    }

    private func title(from file: URL) -> String {
        let stem = file.deletingPathExtension().lastPathComponent
        let withoutDate = stem.replacingOccurrences(
            of: #"^\d{4}-\d{2}-\d{2}-\d{6}-"#,
            with: "",
            options: .regularExpression
        )
        let spaced = withoutDate
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return spaced.isEmpty ? "Earth Agent Note" : spaced.capitalized
    }
}
