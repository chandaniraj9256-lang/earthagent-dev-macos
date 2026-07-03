import Foundation

@main
struct SpokenTextCleanerTests {
    static func main() {
        let markdown = """
        # Plan
        - Open LinkedIn
        - Draft the post
        Visit https://example.com for more.
        """
        let cleanedMarkdown = SpokenTextCleaner.clean(markdown)
        expect(!cleanedMarkdown.contains("#"), "headings should be removed")
        expect(!cleanedMarkdown.contains("https://"), "URLs should be removed")
        expect(!cleanedMarkdown.contains("- Open"), "bullet markers should be removed")
        expect(cleanedMarkdown.contains("Open LinkedIn"), "bullet content should remain")

        let code = """
        Here is the answer.
        ```swift
        print("secret")
        ```
        Use the button in chat.
        """
        let cleanedCode = SpokenTextCleaner.clean(code)
        expect(!cleanedCode.contains("print"), "code blocks should not be spoken")
        expect(cleanedCode.contains("Here is the answer."), "normal text before code should remain")
        expect(cleanedCode.contains("Use the button in chat."), "normal text after code should remain")

        let table = "Name | Status | Next\nEarth | Ready | Talk"
        let cleanedTable = SpokenTextCleaner.clean(table)
        expect(!cleanedTable.contains("|"), "table pipes should be removed")

        let long = "First sentence. " + String(repeating: "Extra detail ", count: 80)
        let shortened = SpokenTextCleaner.clean(long, limit: 48)
        expect(shortened == "First sentence.", "long text should prefer sentence-boundary truncation")

        print("Spoken text cleaner tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write("FAIL: \(message)\n".data(using: .utf8)!)
            exit(1)
        }
    }
}
