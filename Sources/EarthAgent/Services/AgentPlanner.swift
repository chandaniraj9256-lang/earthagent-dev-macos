import Foundation

final class AgentPlanner {
    func plan(for text: String, safetyMode: SafetyMode) -> AgentTask {
        let lowered = text.lowercased()

        if safetyMode == .chatOnly {
            return AgentTask(
                userText: text,
                explanation: "Chat-only mode is on, so I will answer without taking desktop actions.",
                steps: ["I am staying in chat and avoiding external actions."],
                action: .chatOnly,
                requiresConfirmation: false
            )
        }

        if safetyMode == .draftOnly && asksForExternalAction(lowered) {
            return AgentTask(
                userText: text,
                explanation: "Draft-only mode is on, so I will not open apps or websites. I can draft the plan or text for you instead.",
                steps: ["I am keeping this inside Earth Agent and avoiding external actions."],
                action: .chatOnly,
                requiresConfirmation: false
            )
        }

        if isHighRiskRequest(lowered) {
            return AgentTask(
                userText: text,
                explanation: "This is a high-risk external action. I will not send, publish, buy, delete, submit, change accounts, or share private data automatically.",
                steps: [
                    "I will explain the safe way to handle it.",
                    "I can draft text or a checklist for your review.",
                    "The final external action stays under your direct control."
                ],
                action: .needsConfirmation(summary: text),
                requiresConfirmation: true,
                category: .sensitiveAction,
                requiredTools: ["User confirmation", "Safety review"],
                riskLevel: .high,
                expectedResult: "A safe explanation or draft, with the final action left to the user.",
                fallback: "Refuse the external action and offer a draft or checklist instead."
            )
        }

        if asksToLookAtScreen(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will capture the current screen and use it as visual context for my answer.",
                steps: [
                    "I am capturing the current screen.",
                    "I am attaching the screenshot to this chat.",
                    "I will explain what I can see and suggest the next safe step."
                ],
                action: .lookAtScreen(prompt: text),
                requiresConfirmation: safetyMode == .askBeforeActions,
                category: .uiInspection,
                requiredTools: ["Screen capture", "Vision-capable AI provider"],
                riskLevel: .medium,
                expectedResult: "A screenshot-backed answer in chat or voice conversation mode.",
                fallback: "Ask the user to grant Screen Recording permission or attach a screenshot manually."
            )
        }

        if lowered.contains("computer control status") ||
            lowered.contains("advanced computer use") ||
            lowered.contains("computer use status") ||
            lowered.contains("accessibility status") ||
            lowered.contains("can you control my computer") {
            return AgentTask(
                userText: text,
                explanation: "I will check whether Earth can safely use local computer-control tools.",
                steps: [
                    "I am checking Accessibility permission.",
                    "I am checking the active app.",
                    "I am checking available safe computer-use capabilities."
                ],
                action: lowered.contains("advanced") || lowered.contains("computer use")
                    ? .advancedComputerUseReport
                    : .reportComputerControlStatus,
                requiresConfirmation: false
            )
        }

        if lowered.contains("mcp") || lowered.contains("connector") || lowered.contains("connectors") {
            return AgentTask(
                userText: text,
                explanation: "I will show the MCP connector foundation and what is enabled.",
                steps: [
                    "I am reading local connector settings.",
                    "I will not connect to external tools without permission."
                ],
                action: .mcpStatus,
                requiresConfirmation: false
            )
        }

        if lowered.contains("subagent") ||
            lowered.contains("sub agent") ||
            lowered.contains("agent swarm") ||
            lowered.contains("agent swap") ||
            lowered.contains("parallel agent") ||
            lowered.contains("delegate this") ||
            lowered.contains("divide this task") ||
            lowered.contains("split this task") ||
            lowered.contains("long task") ||
            lowered.contains("complex task") ||
            lowered.contains("faster with agents") {
            return AgentTask(
                userText: text,
                explanation: "I can split this into a focused agent swarm and merge the specialist briefs.",
                steps: [
                    "I am choosing the right specialist agents for this request.",
                    "Each agent will work on a focused part of the task.",
                    "I will merge the results into one safe next-step plan."
                ],
                action: .runSubagents(prompt: text),
                requiresConfirmation: false
            )
        }

        if lowered.contains("routine") || lowered.contains("scheduled automation") || lowered.contains("scheduled task") {
            if lowered.contains("create") || lowered.contains("add") || lowered.contains("schedule") {
                let draft = routineDraft(from: text, lowered: lowered)
                return AgentTask(
                    userText: text,
                    explanation: "I can create a local routine draft. It will stay off until you enable it.",
                    steps: [
                        "I am saving the routine locally.",
                        "It will require confirmation before running.",
                        "You can enable or run it from the Agents tab."
                    ],
                    action: .createRoutine(title: draft.title, prompt: draft.prompt),
                    requiresConfirmation: false
                )
            }

            return AgentTask(
                userText: text,
                explanation: "I will show your local routines and their current status.",
                steps: ["I am reading local routine settings."],
                action: .listRoutines,
                requiresConfirmation: false
            )
        }

        if lowered.contains("what app") ||
            lowered.contains("active app") ||
            lowered.contains("which app am i using") {
            return AgentTask(
                userText: text,
                explanation: "I can report the current frontmost app.",
                steps: ["I am reading the active macOS app name."],
                action: .reportActiveApp,
                requiresConfirmation: false
            )
        }

        if lowered.contains("running apps") ||
            lowered.contains("open apps") ||
            lowered.contains("list apps") ||
            lowered.contains("which apps are open") {
            return AgentTask(
                userText: text,
                explanation: "I can list the running apps macOS reports.",
                steps: ["I am reading the local running app list."],
                action: .listRunningApps,
                requiresConfirmation: false
            )
        }

        if asksToExportDiagnostics(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will export a redacted Earth Agent diagnostics report for beta debugging.",
                steps: [
                    "I am checking current launch readiness and app state.",
                    "I am writing a redacted diagnostics report to Documents.",
                    "I will reveal the report in Finder."
                ],
                action: .exportDiagnosticsReport,
                requiresConfirmation: safetyMode == .askBeforeActions,
                category: .uiInspection,
                requiredTools: ["Local file writer", "Finder"],
                riskLevel: .medium,
                expectedResult: "A local diagnostics Markdown report is exported and revealed in Finder.",
                fallback: "Summarize launch readiness in chat and explain where diagnostics will be written."
            )
        }

        if asksToOpenDiagnosticsFolder(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will open the local Earth Agent diagnostics folder.",
                steps: [
                    "I am checking the local diagnostics folder.",
                    "I will create it if it does not exist yet.",
                    "I will open it in Finder."
                ],
                action: .openDiagnosticsFolder,
                requiresConfirmation: safetyMode == .askBeforeActions,
                category: .appOpening,
                requiredTools: ["Local file writer", "Finder"],
                riskLevel: .medium,
                expectedResult: "The Earth Agent diagnostics folder opens in Finder.",
                fallback: "Show the diagnostics folder path so the user can open it manually."
            )
        }

        if asksForLaunchReadiness(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will summarize Earth Agent launch readiness and the setup items that still need attention.",
                steps: [
                    "I am checking provider, permissions, voice, safety, and background readiness.",
                    "I will summarize what is ready and what still needs work.",
                    "I can export a diagnostics report if you want to share the state."
                ],
                action: .showLaunchReadiness,
                requiresConfirmation: false,
                category: .uiInspection,
                requiredTools: ["Local app state"],
                riskLevel: .low,
                expectedResult: "A compact readiness summary appears in chat.",
                fallback: "Explain the most important missing setup items in chat."
            )
        }

        if asksForClipboardSummary(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will read the current text clipboard because you asked, then summarize it in Earth Agent.",
                steps: [
                    "I am reading the current clipboard text.",
                    "I will not monitor future clipboard changes.",
                    "I will summarize or explain the copied text in chat."
                ],
                action: .summarizeClipboard(instruction: text),
                requiresConfirmation: safetyMode == .askBeforeActions,
                category: .uiInspection,
                requiredTools: ["Clipboard", "AI provider"],
                riskLevel: .medium,
                expectedResult: "A useful summary or explanation of the copied text.",
                fallback: "Ask the user to copy text first or paste the content into chat."
            )
        }

        if asksToCopyLastAnswer(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will copy my latest reply to the clipboard.",
                steps: [
                    "I am finding the latest Earth Agent reply.",
                    "I am writing that reply to the clipboard.",
                    "You can paste it anywhere."
                ],
                action: .copyLastAssistantMessage,
                requiresConfirmation: safetyMode == .askBeforeActions,
                category: .uiInspection,
                requiredTools: ["Clipboard"],
                riskLevel: .medium,
                expectedResult: "The latest assistant reply is available on the clipboard.",
                fallback: "Ask the user to send a message first so there is an assistant reply to copy."
            )
        }

        if asksToSaveLastAnswer(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will save my latest reply as a local note.",
                steps: [
                    "I am finding the latest Earth Agent reply.",
                    "I am saving it as a Markdown note in Documents.",
                    "I will open the notes folder so you can find it."
                ],
                action: .saveLastAssistantMessage,
                requiresConfirmation: safetyMode == .askBeforeActions,
                category: .drafting,
                requiredTools: ["Local file writer", "Finder"],
                riskLevel: .medium,
                expectedResult: "The latest assistant reply is saved as a local Markdown note.",
                fallback: "Ask the user to send a message first so there is an assistant reply to save."
            )
        }

        if asksToOpenNotes(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will open your local Earth Agent notes folder.",
                steps: [
                    "I am checking the local notes folder.",
                    "I will create it if it does not exist yet.",
                    "I will open it in Finder."
                ],
                action: .openNotesFolder,
                requiresConfirmation: safetyMode == .askBeforeActions,
                category: .appOpening,
                requiredTools: ["Local file writer", "Finder"],
                riskLevel: .medium,
                expectedResult: "The Earth Agent notes folder opens in Finder.",
                fallback: "Show the notes folder path so the user can open it manually."
            )
        }

        if asksToReadNote(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will read the selected local Earth Agent note in chat.",
                steps: [
                    "I am matching your note number against the recent notes list.",
                    "I will read that saved note locally.",
                    "I will show the note text in Earth Agent."
                ],
                action: .readNote(index: firstNumber(from: lowered)),
                requiresConfirmation: false,
                category: .uiInspection,
                requiredTools: ["Local file reader"],
                riskLevel: .low,
                expectedResult: "The selected Earth Agent note is shown in chat.",
                fallback: "List saved notes first, then ask which note to read."
            )
        }

        if asksToOpenNote(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will open the selected local Earth Agent note.",
                steps: [
                    "I am matching your note number against the recent notes list.",
                    "I will open that note in the default Markdown editor.",
                    "I will not edit the note."
                ],
                action: .openNote(index: firstNumber(from: lowered)),
                requiresConfirmation: safetyMode == .askBeforeActions,
                category: .appOpening,
                requiredTools: ["Local file reader", "Finder"],
                riskLevel: .medium,
                expectedResult: "The selected Earth Agent note opens.",
                fallback: "List saved notes first, then ask which note to open."
            )
        }

        if asksToListNotes(lowered) {
            return AgentTask(
                userText: text,
                explanation: "I will list your recent local Earth Agent notes.",
                steps: [
                    "I am checking the local notes folder.",
                    "I will list recent note files with paths.",
                    "I will not read note contents unless you ask later."
                ],
                action: .listNotes,
                requiresConfirmation: false,
                category: .uiInspection,
                requiredTools: ["Local file reader"],
                riskLevel: .low,
                expectedResult: "Recent Earth Agent notes are listed in chat.",
                fallback: "Open the notes folder so the user can inspect saved notes manually."
            )
        }

        if let appName = focusAppName(from: text, lowered: lowered) {
            return AgentTask(
                userText: text,
                explanation: "I can bring \(appName) forward, but app focus changes need confirmation.",
                steps: [
                    "I will look for a running app matching \(appName).",
                    "After confirmation, I will activate that app."
                ],
                action: .focusApp(name: appName),
                requiresConfirmation: true
            )
        }

        if lowered.hasPrefix("scroll ") || lowered.contains("scroll down") || lowered.contains("scroll up") {
            let direction = lowered.contains("up") ? "up" : "down"
            return AgentTask(
                userText: text,
                explanation: "I can scroll the active app, but I need confirmation before controlling the UI.",
                steps: [
                    "I will check Accessibility permission.",
                    "After confirmation, I will scroll \(direction) in the active app."
                ],
                action: .scroll(direction: direction),
                requiresConfirmation: true
            )
        }

        if lowered.contains("inspect browser") ||
            lowered.contains("read browser") ||
            lowered.contains("what can you see in browser") {
            return AgentTask(
                userText: text,
                explanation: "I will inspect visible browser controls and page elements through Accessibility.",
                steps: [
                    "I am checking Accessibility permission.",
                    "I am reading visible browser UI elements.",
                    "I will show numbered targets you can confirm later."
                ],
                action: .browserInspect,
                requiresConfirmation: false
            )
        }

        if lowered.contains("inspect ui") ||
            lowered.contains("inspect visible") ||
            lowered.contains("show visible elements") ||
            lowered.contains("read ui elements") ||
            lowered.contains("what can you click") {
            return AgentTask(
                userText: text,
                explanation: "I will inspect visible Accessibility UI elements in the active app.",
                steps: [
                    "I am checking Accessibility permission.",
                    "I am reading visible buttons, links, fields, and menu items.",
                    "I will list clickable candidates by number."
                ],
                action: .inspectVisibleElements,
                requiresConfirmation: false
            )
        }

        if let smartOpen = browserCandidateOpenIntent(from: lowered) {
            return AgentTask(
                userText: text,
                explanation: "I can open that browser result, but I need your confirmation before clicking.",
                steps: [
                    "I will use the latest labeled browser results.",
                    "After you confirm, you will have two seconds to focus the browser.",
                    "I will open the matching result."
                ],
                action: .openBrowserCandidate(index: smartOpen.index, kind: smartOpen.kind),
                requiresConfirmation: true
            )
        }

        if lowered.contains("save the result") {
            return AgentTask(
                userText: text,
                explanation: "I can save the latest assistant answer as a local note.",
                steps: [
                    "I will use the latest assistant reply.",
                    "I will save it to the local Earth Agent notes folder.",
                    "I will not upload it anywhere."
                ],
                action: .saveLastAssistantMessage,
                requiresConfirmation: false
            )
        }

        if lowered.contains("draft message") ||
            lowered.contains("write a message") ||
            lowered.contains("message for this") {
            return AgentTask(
                userText: text,
                explanation: "I will draft the message only. I will not send it.",
                steps: [
                    "I am preparing a draft in chat.",
                    "You can edit it before using it anywhere."
                ],
                action: .draftOnly(topic: text),
                requiresConfirmation: false
            )
        }

        if let elementIndex = clickElementIndex(from: lowered) {
            return AgentTask(
                userText: text,
                explanation: "I can click visible element #\(elementIndex), but I need your confirmation first.",
                steps: [
                    "I will use the latest inspected UI element list.",
                    "After you confirm, you will have two seconds to focus the target app.",
                    "I will click element #\(elementIndex)."
                ],
                action: .clickElement(index: elementIndex),
                requiresConfirmation: true
            )
        }

        if let typedText = textToType(from: text, lowered: lowered) {
            return AgentTask(
                userText: text,
                explanation: "I can type this into the currently focused field, but I need your confirmation first.",
                steps: [
                    "I will check Accessibility permission.",
                    "After you confirm, you will have three seconds to click the target text field.",
                    "I will type into the focused field.",
                    "I will stop immediately if you press Stop."
                ],
                action: .typeText(text: typedText),
                requiresConfirmation: true
            )
        }

        if let browserQuery = browserSearchQuery(from: text, lowered: lowered) {
            return AgentTask(
                userText: text,
                explanation: "I can open a browser search for this and then inspect results when you ask.",
                steps: [
                    "I am opening the search page.",
                    "I can inspect visible results next.",
                    "I will not click or submit anything without confirmation."
                ],
                action: .browserSearch(query: browserQuery),
                requiresConfirmation: safetyMode == .askBeforeActions || safetyMode == .draftOnly
            )
        }

        if let shortcut = shortcutToPress(from: lowered) {
            return AgentTask(
                userText: text,
                explanation: "I can press \(shortcut), but keyboard control needs confirmation.",
                steps: [
                    "I will check Accessibility permission.",
                    "After you confirm, you will have two seconds to focus the target app.",
                    "I will press \(shortcut) in the active app."
                ],
                action: .pressShortcut(shortcut: shortcut),
                requiresConfirmation: true
            )
        }

        if lowered.contains("linkedin") && (lowered.contains("post") || lowered.contains("publish") || lowered.contains("message")) {
            return AgentTask(
                userText: text,
                explanation: "I can draft this, but I will not publish or send anything without your final confirmation.",
                steps: [
                    "I am preparing a safe draft first.",
                    "I will keep the final action under your control."
                ],
                action: .draftOnly(topic: text),
                requiresConfirmation: false
            )
        }

        if let searchRange = lowered.range(of: "search for") {
            let queryStart = searchRange.upperBound
            let query = String(text[queryStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return AgentTask(
                userText: text,
                explanation: "I can search the web for this safely.",
                steps: [
                    "I am opening a Google search.",
                    "I can inspect visible results after the page loads.",
                    "I will ask before clicking a result."
                ],
                action: .browserSearch(query: query),
                requiresConfirmation: safetyMode == .askBeforeActions || safetyMode == .draftOnly
            )
        }

        if lowered.hasPrefix("open ") || lowered.contains("open chrome") {
            if lowered.contains("youtube") {
                return openWebsiteTask(text: text, urlString: "https://www.youtube.com", safetyMode: safetyMode)
            }
            if lowered.contains("google") {
                return openWebsiteTask(text: text, urlString: "https://www.google.com", safetyMode: safetyMode)
            }
            if lowered.contains("chrome") {
                return openAppTask(text: text, appName: "Google Chrome", safetyMode: safetyMode)
            }
            if lowered.contains("safari") {
                return openAppTask(text: text, appName: "Safari", safetyMode: safetyMode)
            }
        }

        if lowered.contains("create a simple website") || lowered.contains("create a local website") || lowered.contains("build a website") {
            return AgentTask(
                userText: text,
                explanation: "I can create a starter website as real local files.",
                steps: [
                    "I am creating a website folder in Documents.",
                    "I am writing the HTML, CSS, and README files.",
                    "I will open the folder and preview file so you can inspect them."
                ],
                action: .createWebsite(prompt: text),
                requiresConfirmation: safetyMode == .askBeforeActions
            )
        }

        return AgentTask(
            userText: text,
            explanation: "I will answer in chat first. For external actions, I will ask before doing anything sensitive.",
            steps: ["I am thinking through the safest answer."],
            action: .chatOnly,
            requiresConfirmation: false
        )
    }

    private func openAppTask(text: String, appName: String, safetyMode: SafetyMode) -> AgentTask {
        AgentTask(
            userText: text,
            explanation: "I can open \(appName) for you.",
            steps: [
                "I am opening \(appName) now.",
                "I will stop if you press Stop or take over."
            ],
            action: .openApp(name: appName),
            requiresConfirmation: safetyMode == .askBeforeActions || safetyMode == .draftOnly
        )
    }

    private func openWebsiteTask(text: String, urlString: String, safetyMode: SafetyMode) -> AgentTask {
        let url = URL(string: urlString) ?? URL(string: "https://www.google.com")!
        return AgentTask(
            userText: text,
            explanation: "I can open this website safely.",
            steps: [
                "I am opening \(url.host ?? url.absoluteString) now.",
                "I will not click, post, or send anything without confirmation."
            ],
            action: .openWebsite(url: url),
            requiresConfirmation: safetyMode == .askBeforeActions || safetyMode == .draftOnly
        )
    }

    private func asksForExternalAction(_ lowered: String) -> Bool {
        lowered.hasPrefix("open ") ||
            lowered.contains("open chrome") ||
            lowered.contains("search for") ||
            lowered.contains("browser search") ||
            lowered.contains("google search") ||
            lowered.contains("open result") ||
            lowered.contains("clipboard") ||
            lowered.contains("copied text") ||
            lowered.contains("copy last") ||
            lowered.contains("copy your") ||
            lowered.contains("save last") ||
            lowered.contains("save your") ||
            lowered.contains("open notes") ||
            lowered.contains("show notes") ||
            lowered.contains("focus ") ||
            lowered.contains("scroll ") ||
            lowered.contains("publish") ||
            lowered.contains("send") ||
            lowered.contains("click") ||
            lowered.contains("type ") ||
            lowered.contains("press ")
    }

    private func asksToLookAtScreen(_ lowered: String) -> Bool {
        let phrases = [
            "look at my screen",
            "look at this screen",
            "look at this",
            "what is on my screen",
            "what's on my screen",
            "what do you see",
            "analyze my screen",
            "analyze this screen",
            "explain my screen",
            "explain what is on my screen",
            "read my screen",
            "capture my screen"
        ]
        return phrases.contains { lowered.contains($0) } ||
            (lowered.contains("screen") && (lowered.contains("help me") || lowered.contains("explain") || lowered.contains("see")))
    }

    private func asksForClipboardSummary(_ lowered: String) -> Bool {
        let contextMatches = lowered.contains("clipboard") ||
            lowered.contains("copied text") ||
            lowered.contains("copied content") ||
            lowered.contains("what i copied") ||
            lowered.contains("what's copied")
        let actionMatches = lowered.contains("summarize") ||
            lowered.contains("summary") ||
            lowered.contains("explain") ||
            lowered.contains("read") ||
            lowered.contains("what is")
        return contextMatches && actionMatches
    }

    private func asksForLaunchReadiness(_ lowered: String) -> Bool {
        let readinessTerms = lowered.contains("launch readiness") ||
            lowered.contains("beta readiness") ||
            lowered.contains("readiness report") ||
            lowered.contains("app health") ||
            lowered.contains("health report") ||
            lowered.contains("is earth ready") ||
            lowered.contains("are we ready")
        let actionTerms = lowered.contains("show") ||
            lowered.contains("check") ||
            lowered.contains("review") ||
            lowered.contains("what is") ||
            lowered.contains("how is") ||
            lowered.contains("status") ||
            lowered.contains("report")
        return readinessTerms && actionTerms
    }

    private func asksToExportDiagnostics(_ lowered: String) -> Bool {
        let diagnosticsTerms = lowered.contains("diagnostics") ||
            lowered.contains("debug report") ||
            lowered.contains("support report") ||
            lowered.contains("bug report")
        let exportTerms = lowered.contains("export") ||
            lowered.contains("save") ||
            lowered.contains("create") ||
            lowered.contains("generate")
        return diagnosticsTerms && exportTerms
    }

    private func asksToOpenDiagnosticsFolder(_ lowered: String) -> Bool {
        let diagnosticsTerms = lowered.contains("diagnostics") ||
            lowered.contains("debug report") ||
            lowered.contains("support report")
        let openTerms = lowered.contains("open") ||
            lowered.contains("show") ||
            lowered.contains("find")
        let folderTerms = lowered.contains("folder") ||
            lowered.contains("directory") ||
            lowered.contains("reports")
        return diagnosticsTerms && openTerms && folderTerms
    }

    private func asksToCopyLastAnswer(_ lowered: String) -> Bool {
        let copyMatches = lowered.contains("copy")
        let targetMatches = lowered.contains("last answer") ||
            lowered.contains("last reply") ||
            lowered.contains("last response") ||
            lowered.contains("your answer") ||
            lowered.contains("your reply") ||
            lowered.contains("your response")
        let clipboardMatches = lowered.contains("clipboard") ||
            lowered.contains("pasteboard") ||
            lowered.contains("copy ")
        return copyMatches && targetMatches && clipboardMatches
    }

    private func asksToSaveLastAnswer(_ lowered: String) -> Bool {
        let saveMatches = lowered.contains("save") || lowered.contains("export")
        let targetMatches = lowered.contains("last answer") ||
            lowered.contains("last reply") ||
            lowered.contains("last response") ||
            lowered.contains("your answer") ||
            lowered.contains("your reply") ||
            lowered.contains("your response")
        let noteMatches = lowered.contains("note") ||
            lowered.contains("file") ||
            lowered.contains("markdown") ||
            lowered.contains("save ")
        return saveMatches && targetMatches && noteMatches
    }

    private func asksToOpenNotes(_ lowered: String) -> Bool {
        let openMatches = lowered.contains("open") || lowered.contains("find")
        let notesMatches = lowered.contains("earth notes") ||
            lowered.contains("earth agent notes") ||
            lowered.contains("notes folder") ||
            lowered.contains("my notes")
        return openMatches && notesMatches
    }

    private func asksToOpenNote(_ lowered: String) -> Bool {
        let openMatches = lowered.contains("open") || lowered.contains("show")
        let singularNote = lowered.contains("note ")
        let numbered = firstNumber(from: lowered) != nil
        return openMatches && singularNote && numbered
    }

    private func asksToReadNote(_ lowered: String) -> Bool {
        let readMatches = lowered.contains("read") ||
            lowered.contains("summarize") ||
            lowered.contains("show note") && lowered.contains("in chat")
        let singularNote = lowered.contains("note ")
        let numbered = firstNumber(from: lowered) != nil
        return readMatches && singularNote && numbered
    }

    private func asksToListNotes(_ lowered: String) -> Bool {
        let listMatches = lowered.contains("list") ||
            lowered.contains("show") ||
            lowered.contains("what notes") ||
            lowered.contains("recent notes")
        let notesMatches = lowered.contains("earth notes") ||
            lowered.contains("earth agent notes") ||
            lowered.contains("saved notes") ||
            lowered.contains("my notes") ||
            lowered.contains("notes")
        return listMatches && notesMatches
    }

    private func isHighRiskRequest(_ lowered: String) -> Bool {
        let highRiskPhrases = [
            "send message",
            "send email",
            "publish",
            "post it",
            "submit application",
            "apply for",
            "buy",
            "purchase",
            "delete",
            "remove file",
            "change account",
            "account settings",
            "share my",
            "send money",
            "payment"
        ]
        return highRiskPhrases.contains { lowered.contains($0) }
    }

    private func routineDraft(from text: String, lowered: String) -> (title: String, prompt: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let title: String
        if lowered.contains("website") {
            title = "Website routine"
        } else if lowered.contains("research") {
            title = "Research routine"
        } else if lowered.contains("draft") || lowered.contains("write") {
            title = "Writing routine"
        } else {
            title = "Custom routine"
        }

        let prompt = trimmed
            .replacingOccurrences(of: "create routine", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "add routine", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "schedule", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (title, prompt.isEmpty ? trimmed : prompt)
    }

    private func focusAppName(from text: String, lowered: String) -> String? {
        let prefixes = ["focus app ", "focus ", "bring forward ", "switch to "]
        for prefix in prefixes where lowered.hasPrefix(prefix) {
            let index = text.index(text.startIndex, offsetBy: prefix.count)
            let value = String(text[index...]).trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            return value.isEmpty ? nil : value
        }
        return nil
    }

    private func textToType(from text: String, lowered: String) -> String? {
        let prefixes = [
            "type this:",
            "type this",
            "type ",
            "write this:",
            "write this"
        ]
        for prefix in prefixes where lowered.hasPrefix(prefix) {
            let index = text.index(text.startIndex, offsetBy: prefix.count)
            let value = String(text[index...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
        return nil
    }

    private func browserCandidateOpenIntent(from lowered: String) -> (index: Int?, kind: String?)? {
        guard lowered.contains("open") &&
            (lowered.contains("result") || lowered.contains("link") || lowered.contains("page")) else {
            return nil
        }
        return (firstNumber(from: lowered), nil)
    }

    private func browserSearchQuery(from text: String, lowered: String) -> String? {
        let prefixes = [
            "browser search for",
            "google search for",
            "search google for",
            "search the web for"
        ]
        for prefix in prefixes where lowered.hasPrefix(prefix) {
            let index = text.index(text.startIndex, offsetBy: prefix.count)
            let value = String(text[index...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
        return nil
    }

    private func shortcutToPress(from lowered: String) -> String? {
        let supported = [
            "command l": "cmd+l",
            "cmd l": "cmd+l",
            "command a": "cmd+a",
            "cmd a": "cmd+a",
            "command c": "cmd+c",
            "cmd c": "cmd+c",
            "command v": "cmd+v",
            "cmd v": "cmd+v",
            "command s": "cmd+s",
            "cmd s": "cmd+s",
            "command w": "cmd+w",
            "cmd w": "cmd+w",
            "press enter": "return",
            "press return": "return",
            "press escape": "escape",
            "press tab": "tab"
        ]
        guard lowered.hasPrefix("press ") else { return nil }
        return supported.first { lowered.contains($0.key) }?.value
    }

    private func clickElementIndex(from lowered: String) -> Int? {
        guard lowered.contains("click element") || lowered.contains("click #") else { return nil }
        return firstNumber(from: lowered)
    }

    private func firstNumber(from lowered: String) -> Int? {
        lowered
            .split { !$0.isNumber }
            .compactMap { Int($0) }
            .first
    }
}
