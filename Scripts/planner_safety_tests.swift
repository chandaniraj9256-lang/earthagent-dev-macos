import Foundation

@main
struct PlannerSafetyTests {
    static func main() {
        let planner = AgentPlanner()

        test("high-risk publish requires confirmation") {
            let task = planner.plan(for: "Publish this LinkedIn post and send it now", safetyMode: .autopilotSafe)
            require(task.requiresConfirmation)
            require(task.category == .sensitiveAction)
            require(task.riskLevel == .high)
            if case .needsConfirmation = task.action {
                return
            }
            fail("Expected needsConfirmation action.")
        }

        test("draft-only mode blocks external opening") {
            let task = planner.plan(for: "Open Chrome and search for remote digital marketing jobs", safetyMode: .draftOnly)
            require(!task.requiresConfirmation)
            require(task.action == .chatOnly)
            require(task.category == .chatAnswer)
        }

        test("look at screen routes to vision action") {
            let task = planner.plan(for: "Look at my screen and help me understand what to do next", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .uiInspection)
            require(task.riskLevel == .medium)
            if case .lookAtScreen(let prompt) = task.action {
                require(prompt.localizedCaseInsensitiveContains("look at my screen"))
                return
            }
            fail("Expected lookAtScreen action.")
        }

        test("ask-before-actions confirms browser search") {
            let task = planner.plan(for: "Search the web for SwiftUI animation examples", safetyMode: .askBeforeActions)
            require(task.requiresConfirmation)
            if case .browserSearch(let query) = task.action {
                require(query.localizedCaseInsensitiveContains("SwiftUI animation examples"))
                return
            }
            fail("Expected browserSearch action.")
        }

        test("typing into focused field requires confirmation") {
            let task = planner.plan(for: "Type this: Hello from Earth Agent", safetyMode: .autopilotSafe)
            require(task.requiresConfirmation)
            require(task.riskLevel == .high)
            if case .typeText(let text) = task.action {
                require(text == "Hello from Earth Agent")
                return
            }
            fail("Expected typeText action.")
        }

        test("clipboard summary reads clipboard only on explicit request") {
            let task = planner.plan(for: "Summarize my clipboard", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .uiInspection)
            require(task.riskLevel == .medium)
            if case .summarizeClipboard(let instruction) = task.action {
                require(instruction.localizedCaseInsensitiveContains("clipboard"))
                return
            }
            fail("Expected summarizeClipboard action.")
        }

        test("ask-before-actions confirms clipboard read") {
            let task = planner.plan(for: "Explain the copied text", safetyMode: .askBeforeActions)
            require(task.requiresConfirmation)
            if case .summarizeClipboard = task.action {
                return
            }
            fail("Expected summarizeClipboard action.")
        }

        test("copy last answer routes to clipboard write") {
            let task = planner.plan(for: "Copy your last answer to clipboard", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.riskLevel == .medium)
            if case .copyLastAssistantMessage = task.action {
                return
            }
            fail("Expected copyLastAssistantMessage action.")
        }

        test("ask-before-actions confirms clipboard write") {
            let task = planner.plan(for: "Copy your last reply", safetyMode: .askBeforeActions)
            require(task.requiresConfirmation)
            if case .copyLastAssistantMessage = task.action {
                return
            }
            fail("Expected copyLastAssistantMessage action.")
        }

        test("save last answer routes to local note") {
            let task = planner.plan(for: "Save your last answer as a note", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .drafting)
            require(task.riskLevel == .medium)
            if case .saveLastAssistantMessage = task.action {
                return
            }
            fail("Expected saveLastAssistantMessage action.")
        }

        test("ask-before-actions confirms note save") {
            let task = planner.plan(for: "Export your last response to markdown", safetyMode: .askBeforeActions)
            require(task.requiresConfirmation)
            if case .saveLastAssistantMessage = task.action {
                return
            }
            fail("Expected saveLastAssistantMessage action.")
        }

        test("open notes folder routes to finder action") {
            let task = planner.plan(for: "Open my Earth Agent notes folder", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .appOpening)
            require(task.riskLevel == .medium)
            if case .openNotesFolder = task.action {
                return
            }
            fail("Expected openNotesFolder action.")
        }

        test("ask-before-actions confirms opening notes folder") {
            let task = planner.plan(for: "Show my saved notes", safetyMode: .askBeforeActions)
            require(!task.requiresConfirmation)
            if case .listNotes = task.action {
                return
            }
            fail("Expected listNotes action.")
        }

        test("list saved notes stays low risk") {
            let task = planner.plan(for: "List my saved notes", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .uiInspection)
            require(task.riskLevel == .low)
            if case .listNotes = task.action {
                return
            }
            fail("Expected listNotes action.")
        }

        test("open note by number routes to local note open") {
            let task = planner.plan(for: "Open note 1", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .appOpening)
            require(task.riskLevel == .medium)
            if case .openNote(let index) = task.action {
                require(index == 1)
                return
            }
            fail("Expected openNote action.")
        }

        test("ask-before-actions confirms opening numbered note") {
            let task = planner.plan(for: "Show note 2", safetyMode: .askBeforeActions)
            require(task.requiresConfirmation)
            if case .openNote(let index) = task.action {
                require(index == 2)
                return
            }
            fail("Expected openNote action.")
        }

        test("read note by number stays in chat") {
            let task = planner.plan(for: "Read note 1", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .uiInspection)
            require(task.riskLevel == .low)
            if case .readNote(let index) = task.action {
                require(index == 1)
                return
            }
            fail("Expected readNote action.")
        }

        test("launch readiness report stays low risk") {
            let task = planner.plan(for: "Show launch readiness report", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .uiInspection)
            require(task.riskLevel == .low)
            if case .showLaunchReadiness = task.action {
                return
            }
            fail("Expected showLaunchReadiness action.")
        }

        test("export diagnostics routes to local report action") {
            let task = planner.plan(for: "Export diagnostics report", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .uiInspection)
            require(task.riskLevel == .medium)
            if case .exportDiagnosticsReport = task.action {
                return
            }
            fail("Expected exportDiagnosticsReport action.")
        }

        test("open diagnostics folder routes to finder action") {
            let task = planner.plan(for: "Open diagnostics folder", safetyMode: .autopilotSafe)
            require(!task.requiresConfirmation)
            require(task.category == .appOpening)
            require(task.riskLevel == .medium)
            if case .openDiagnosticsFolder = task.action {
                return
            }
            fail("Expected openDiagnosticsFolder action.")
        }

        print("Planner safety tests passed.")
    }

    private static func test(_ name: String, _ body: () -> Void) {
        body()
        print("✓ \(name)")
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String = "Assertion failed") {
        if !condition() {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        fputs("Planner safety test failed: \(message)\n", stderr)
        exit(1)
    }
}
