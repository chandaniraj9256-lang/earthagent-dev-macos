import AppKit
import Foundation

@main
struct ClipboardServiceTests {
    static func main() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("earth-agent-clipboard-tests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        let service = ClipboardService(pasteboard: pasteboard)

        expectThrows("empty clipboard should fail") {
            _ = try service.readText()
        }

        tryOrFail("write text") {
            try service.writeText("  Hello clipboard  ")
        }
        expect(pasteboard.string(forType: .string) == "Hello clipboard", "writeText should trim whitespace")

        tryOrFail("read text") {
            let value = try service.readText()
            expect(value == "Hello clipboard", "readText should return stored text")
        }

        tryOrFail("write long text") {
            try service.writeText(String(repeating: "A", count: 40))
        }
        tryOrFail("read truncated text") {
            let value = try service.readText(limit: 10)
            expect(value.hasPrefix("AAAAAAAAAA"), "readText should keep requested prefix")
            expect(value.contains("truncated"), "readText should mark truncation")
        }

        expectThrows("blank writes should fail") {
            try service.writeText("   ")
        }

        print("Clipboard service tests passed.")
    }

    private static func tryOrFail(_ label: String, _ body: () throws -> Void) {
        do {
            try body()
        } catch {
            fail("\(label) threw \(error.localizedDescription)")
        }
    }

    private static func expectThrows(_ label: String, _ body: () throws -> Void) {
        do {
            try body()
            fail("\(label) did not throw")
        } catch {
            return
        }
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
