import Foundation

@main
struct NoteWriterTests {
    static func main() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("earth-agent-note-tests-\(UUID().uuidString)", isDirectory: true)
        let writer = NoteWriterService(rootDirectory: root)
        let date = Date(timeIntervalSince1970: 1_767_225_600)

        do {
            let result = try writer.save(title: "Launch Plan / Next Steps", body: "Ship the next useful workflow.", createdAt: date)
            expect(result.directory == root, "note directory should be the injected root")
            expect(FileManager.default.fileExists(atPath: result.file.path), "note file should exist")
            expect(result.file.lastPathComponent.contains("launch-plan-next-steps"), "filename should include sanitized title")
            let body = try String(contentsOf: result.file, encoding: .utf8)
            expect(body.contains("# Launch Plan / Next Steps"), "note title should be present")
            expect(body.contains("Ship the next useful workflow."), "note body should be present")
            let notesDirectory = try writer.ensureNotesDirectory()
            expect(notesDirectory == root, "ensureNotesDirectory should return the injected root")
            expect(FileManager.default.fileExists(atPath: notesDirectory.path), "ensureNotesDirectory should create the folder")

            _ = try writer.save(title: "Second Note", body: "Another saved answer.", createdAt: date.addingTimeInterval(60))
            let notes = try writer.listNotes()
            expect(notes.count == 2, "listNotes should return saved markdown notes")
            expect(notes.first?.title == "Second Note", "listNotes should sort newest first")
            expect(notes.map { $0.file.lastPathComponent }.contains(result.file.lastPathComponent), "listNotes should include the first saved note")
            let readBack = try writer.read(notes.first!)
            expect(readBack.contains("Another saved answer."), "read should return note markdown text")
        } catch {
            fail("save note threw \(error.localizedDescription)")
        }

        do {
            _ = try writer.save(title: "Blank", body: "   ", createdAt: date)
            fail("blank note body should throw")
        } catch {
            // Expected.
        }

        try? FileManager.default.removeItem(at: root)
        print("Note writer tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write("FAIL: \(message)\n".data(using: .utf8)!)
        exit(1)
    }
}
