import Foundation

@main
struct StreamingClientTests {
    static func main() {
        expectToken(helloEvent, "Hello", "single streaming token")
        expectToken(multiLineEvent, " fast Earth", "multi data-line event")
        expectToken(roleOnlyEvent, nil, "role-only event has no spoken token")
        expectToken(doneEvent, nil, "done event has no token")

        print("Streaming parser tests passed.")
    }

    @discardableResult
    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
        if condition() { return true }
        FileHandle.standardError.write("FAIL: \(message)\n".data(using: .utf8)!)
        exit(1)
    }

    private static func expectToken(_ event: String, _ expected: String?, _ message: String) {
        do {
            let token = try StreamingChatParser.token(from: event)
            expect(token == expected, "\(message). Expected \(String(describing: expected)), got \(String(describing: token))")
        } catch {
            FileHandle.standardError.write("FAIL: \(message). Threw \(error.localizedDescription)\n".data(using: .utf8)!)
            exit(1)
        }
    }
}

let helloEvent = """
data: {"choices":[{"delta":{"content":"Hello"}}]}

"""

let multiLineEvent = """
event: message
data: {"choices":[{"delta":{"content":" fast"}}]}
data: {"choices":[{"delta":{"content":" Earth"}}]}

"""

let roleOnlyEvent = """
data: {"choices":[{"delta":{"role":"assistant"}}]}

"""

let doneEvent = """
data: [DONE]

"""
