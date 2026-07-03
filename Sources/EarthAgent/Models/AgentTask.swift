import Foundation

struct AgentTask: Identifiable, Equatable {
    enum Category: String, Equatable {
        case chatAnswer = "Chat answer"
        case drafting = "Drafting task"
        case browserSearch = "Browser/search task"
        case appOpening = "App opening task"
        case uiInspection = "UI inspection task"
        case computerControl = "Computer control task"
        case memory = "Memory task"
        case routine = "Routine task"
        case sensitiveAction = "Sensitive action"
        case unsupported = "Unsupported request"
    }

    enum RiskLevel: String, Equatable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var shortDescription: String {
            switch self {
            case .low:
                return "Safe response, draft, summary, or basic navigation."
            case .medium:
                return "Touches apps, files, UI, typing, clicking, or saved local data."
            case .high:
                return "Could send, publish, buy, delete, change accounts, or expose private data."
            }
        }
    }

    enum Action: Equatable {
        case chatOnly
        case openApp(name: String)
        case openWebsite(url: URL)
        case draftOnly(topic: String)
        case createWebsite(prompt: String)
        case reportActiveApp
        case reportComputerControlStatus
        case inspectVisibleElements
        case clickElement(index: Int)
        case browserSearch(query: String)
        case browserInspect
        case openBrowserCandidate(index: Int?, kind: String?)
        case typeText(text: String)
        case pressShortcut(shortcut: String)
        case listRoutines
        case runRoutine(id: UUID)
        case createRoutine(title: String, prompt: String)
        case runSubagents(prompt: String)
        case mcpStatus
        case advancedComputerUseReport
        case listRunningApps
        case showLaunchReadiness
        case exportDiagnosticsReport
        case openDiagnosticsFolder
        case lookAtScreen(prompt: String)
        case summarizeClipboard(instruction: String)
        case copyLastAssistantMessage
        case saveLastAssistantMessage
        case openNotesFolder
        case listNotes
        case openNote(index: Int?)
        case readNote(index: Int?)
        case focusApp(name: String)
        case scroll(direction: String)
        case needsConfirmation(summary: String)
    }

    let id = UUID()
    let userText: String
    let explanation: String
    let steps: [String]
    let action: Action
    let requiresConfirmation: Bool
    let category: Category
    let requiredTools: [String]
    let riskLevel: RiskLevel
    let expectedResult: String
    let fallback: String

    init(
        userText: String,
        explanation: String,
        steps: [String],
        action: Action,
        requiresConfirmation: Bool,
        category: Category? = nil,
        requiredTools: [String]? = nil,
        riskLevel: RiskLevel? = nil,
        expectedResult: String? = nil,
        fallback: String? = nil
    ) {
        self.userText = userText
        self.explanation = explanation
        self.steps = steps
        self.action = action
        self.requiresConfirmation = requiresConfirmation || (riskLevel ?? Self.defaultRisk(for: action)) == .high
        self.category = category ?? Self.defaultCategory(for: action)
        self.requiredTools = requiredTools ?? Self.defaultTools(for: action)
        self.riskLevel = riskLevel ?? Self.defaultRisk(for: action)
        self.expectedResult = expectedResult ?? Self.defaultExpectedResult(for: action)
        self.fallback = fallback ?? Self.defaultFallback(for: action)
    }

    private static func defaultCategory(for action: Action) -> Category {
        switch action {
        case .chatOnly:
            return .chatAnswer
        case .draftOnly, .saveLastAssistantMessage:
            return .drafting
        case .browserSearch, .browserInspect, .openBrowserCandidate:
            return .browserSearch
        case .openApp, .openWebsite, .openNotesFolder, .openNote:
            return .appOpening
        case .listNotes, .readNote, .showLaunchReadiness:
            return .uiInspection
        case .inspectVisibleElements, .reportActiveApp, .reportComputerControlStatus, .advancedComputerUseReport, .listRunningApps, .lookAtScreen, .summarizeClipboard, .copyLastAssistantMessage, .exportDiagnosticsReport:
            return .uiInspection
        case .clickElement, .typeText, .pressShortcut, .focusApp, .scroll:
            return .computerControl
        case .listRoutines, .runRoutine, .createRoutine:
            return .routine
        case .runSubagents, .mcpStatus:
            return .chatAnswer
        case .createWebsite:
            return .drafting
        case .openDiagnosticsFolder:
            return .appOpening
        case .needsConfirmation:
            return .sensitiveAction
        }
    }

    private static func defaultRisk(for action: Action) -> RiskLevel {
        switch action {
        case .chatOnly, .draftOnly, .reportActiveApp, .reportComputerControlStatus, .inspectVisibleElements, .browserInspect, .listRoutines, .runSubagents, .mcpStatus, .advancedComputerUseReport, .listRunningApps, .listNotes, .readNote, .showLaunchReadiness:
            return .low
        case .openApp, .openWebsite, .browserSearch, .createWebsite, .createRoutine, .runRoutine, .lookAtScreen, .summarizeClipboard, .copyLastAssistantMessage, .saveLastAssistantMessage, .openNotesFolder, .openNote, .exportDiagnosticsReport, .openDiagnosticsFolder:
            return .medium
        case .openBrowserCandidate, .clickElement, .typeText, .pressShortcut, .focusApp, .scroll, .needsConfirmation:
            return .high
        }
    }

    private static func defaultTools(for action: Action) -> [String] {
        switch action {
        case .chatOnly, .draftOnly, .runSubagents:
            return ["AI provider"]
        case .openApp:
            return ["macOS app launcher"]
        case .openWebsite, .browserSearch:
            return ["Browser launcher"]
        case .createWebsite:
            return ["Local file writer", "Finder", "Browser preview"]
        case .saveLastAssistantMessage, .openNotesFolder, .listNotes, .openNote, .readNote:
            return ["Local file writer", "Finder"]
        case .reportActiveApp, .reportComputerControlStatus, .advancedComputerUseReport, .listRunningApps, .showLaunchReadiness:
            return ["macOS workspace"]
        case .exportDiagnosticsReport, .openDiagnosticsFolder:
            return ["Local file writer", "Finder"]
        case .lookAtScreen:
            return ["Screen capture", "Vision-capable AI provider"]
        case .summarizeClipboard, .copyLastAssistantMessage:
            return ["Clipboard", "AI provider"]
        case .inspectVisibleElements, .browserInspect:
            return ["Accessibility"]
        case .clickElement, .typeText, .pressShortcut, .focusApp, .scroll:
            return ["Accessibility", "macOS input events", "Confirmation"]
        case .openBrowserCandidate:
            return ["Browser", "Accessibility", "Confirmation"]
        case .listRoutines, .runRoutine, .createRoutine:
            return ["Local routines"]
        case .mcpStatus:
            return ["Local connector registry"]
        case .needsConfirmation:
            return ["Confirmation"]
        }
    }

    private static func defaultExpectedResult(for action: Action) -> String {
        switch action {
        case .chatOnly:
            return "A helpful answer in chat."
        case .draftOnly:
            return "Draft text the user can review before sending or publishing."
        case .openApp:
            return "The requested app opens or comes forward."
        case .openWebsite:
            return "The website opens in the default browser."
        case .createWebsite:
            return "A local website folder with editable files and a browser preview."
        case .reportActiveApp:
            return "The current frontmost app is shown."
        case .reportComputerControlStatus, .advancedComputerUseReport:
            return "The user sees computer-control readiness and permission status."
        case .inspectVisibleElements, .browserInspect:
            return "Visible UI elements are listed with numbers."
        case .clickElement:
            return "The confirmed numbered element is clicked."
        case .browserSearch:
            return "A search page opens for the requested query."
        case .openBrowserCandidate:
            return "The confirmed browser result opens."
        case .typeText:
            return "Confirmed text is typed into the focused field."
        case .pressShortcut:
            return "The confirmed keyboard shortcut is pressed."
        case .listRoutines:
            return "Local routines and statuses are shown."
        case .runRoutine:
            return "The selected routine runs inside Earth Agent."
        case .createRoutine:
            return "A disabled routine draft is saved locally."
        case .runSubagents:
            return "Specialist agent briefs are summarized into a next step."
        case .mcpStatus:
            return "Connector readiness is shown without external actions."
        case .listRunningApps:
            return "Running apps are listed."
        case .showLaunchReadiness:
            return "Earth summarizes beta readiness and the setup items that still need attention."
        case .exportDiagnosticsReport:
            return "A redacted local diagnostics report is saved and revealed in Finder."
        case .openDiagnosticsFolder:
            return "The Earth Agent diagnostics folder opens in Finder."
        case .lookAtScreen:
            return "A screenshot is captured, attached, and explained by the selected AI model."
        case .summarizeClipboard:
            return "The current text clipboard is summarized or explained in chat."
        case .copyLastAssistantMessage:
            return "The latest assistant reply is copied to the clipboard."
        case .saveLastAssistantMessage:
            return "The latest assistant reply is saved as a local Markdown note."
        case .openNotesFolder:
            return "The local Earth Agent notes folder opens in Finder."
        case .listNotes:
            return "Recent local Earth Agent notes are listed in chat."
        case .openNote:
            return "The selected local Earth Agent note opens."
        case .readNote:
            return "The selected local Earth Agent note is shown in chat."
        case .focusApp:
            return "The confirmed app is brought forward."
        case .scroll:
            return "The active app scrolls after confirmation."
        case .needsConfirmation:
            return "The user sees a final confirmation request."
        }
    }

    private static func defaultFallback(for action: Action) -> String {
        switch action {
        case .clickElement, .typeText, .pressShortcut, .focusApp, .scroll, .inspectVisibleElements, .browserInspect:
            return "Ask the user to grant Accessibility permission, inspect again, or take over manually."
        case .lookAtScreen:
            return "Ask the user to grant Screen Recording permission or attach a screenshot manually."
        case .summarizeClipboard:
            return "Ask the user to copy text first, or paste the content directly into chat."
        case .copyLastAssistantMessage:
            return "Ask the user to send a message first so there is an assistant reply to copy."
        case .saveLastAssistantMessage:
            return "Ask the user to send a message first so there is an assistant reply to save."
        case .openNotesFolder:
            return "Show the notes folder path so the user can open it manually."
        case .listNotes:
            return "Open the notes folder so the user can inspect saved notes manually."
        case .openNote:
            return "List saved notes first, then ask the user which note to open."
        case .readNote:
            return "List saved notes first, then ask the user which note to read."
        case .showLaunchReadiness:
            return "Explain the missing setup items in chat and point the user to Settings or Safety."
        case .exportDiagnosticsReport:
            return "Keep the readiness summary in chat and explain where diagnostics will be stored."
        case .openDiagnosticsFolder:
            return "Show the diagnostics folder path so the user can open it manually."
        case .openApp, .openWebsite, .browserSearch:
            return "Explain the issue and provide the URL or app name for manual action."
        case .createWebsite:
            return "Return the website content in chat so the user can copy it later."
        case .runSubagents, .chatOnly, .draftOnly:
            return "Give a concise chat answer and explain what failed."
        case .listRoutines, .runRoutine, .createRoutine:
            return "Show the routine status and keep actions local."
        case .mcpStatus:
            return "Show connector settings and explain that execution is not enabled yet."
        default:
            return "Stop safely, explain what happened, and ask the user what to do next."
        }
    }
}
