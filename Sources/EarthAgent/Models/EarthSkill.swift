import Foundation

struct EarthSkill: Identifiable, Codable, Equatable {
    enum Category: String, CaseIterable, Codable, Identifiable {
        case productivity = "Productivity"
        case research = "Research"
        case communication = "Communication"
        case macOS = "Mac"
        case automation = "Automation"
        case creative = "Creative"
        case safety = "Safety"

        var id: String { rawValue }
    }

    let id: String
    let name: String
    let summary: String
    let category: Category
    let requiredTools: [String]
    let requiredPermissions: [AgentToolDescriptor.Permission]
    let triggerPhrases: [String]
    let instructions: String
    let isBuiltIn: Bool

    static let builtIns: [EarthSkill] = [
        EarthSkill(
            id: "browser-research",
            name: "Browser Research",
            summary: "Searches the web, inspects results, and summarizes next steps.",
            category: .research,
            requiredTools: ["search_web", "inspect_ui"],
            requiredPermissions: [.aiProvider],
            triggerPhrases: ["research", "search the web", "find sources"],
            instructions: "Search first, inspect visible results when allowed, summarize sources, and ask before opening external results.",
            isBuiltIn: true
        ),
        EarthSkill(
            id: "document-summary",
            name: "Document Summary",
            summary: "Summarizes PDFs, images, notes, and uploaded files.",
            category: .productivity,
            requiredTools: ["chat_answer"],
            requiredPermissions: [.aiProvider],
            triggerPhrases: ["summarize file", "summarize document", "review this pdf"],
            instructions: "Extract key points, decisions, risks, and next actions. Mention if the file could not be fully read.",
            isBuiltIn: true
        ),
        EarthSkill(
            id: "message-drafting",
            name: "Message Drafting",
            summary: "Drafts messages and emails without sending them.",
            category: .communication,
            requiredTools: ["chat_answer"],
            requiredPermissions: [.aiProvider],
            triggerPhrases: ["draft message", "write email", "reply to"],
            instructions: "Draft only. Never claim a message was sent. Ask for tone, audience, and final confirmation before any external action.",
            isBuiltIn: true
        ),
        EarthSkill(
            id: "meeting-notes",
            name: "Meeting Notes",
            summary: "Turns rough notes into clean decisions and action items.",
            category: .productivity,
            requiredTools: ["chat_answer"],
            requiredPermissions: [.aiProvider],
            triggerPhrases: ["meeting notes", "action items", "summarize notes"],
            instructions: "Produce sections for summary, decisions, action items, owners, open questions, and follow-up draft.",
            isBuiltIn: true
        ),
        EarthSkill(
            id: "website-builder",
            name: "Website Builder",
            summary: "Creates a simple local website for an idea or product.",
            category: .creative,
            requiredTools: ["create_website"],
            requiredPermissions: [.localFiles],
            triggerPhrases: ["create website", "build website", "local website"],
            instructions: "Create local files only. Do not publish without final confirmation.",
            isBuiltIn: true
        ),
        EarthSkill(
            id: "screen-explainer",
            name: "Screen Explainer",
            summary: "Explains what is visible on screen and suggests the next safe step.",
            category: .macOS,
            requiredTools: ["look_at_screen"],
            requiredPermissions: [.screenRecording, .aiProvider],
            triggerPhrases: ["look at my screen", "what do I do next", "explain screen"],
            instructions: "Describe visible UI, avoid hidden/private assumptions, and ask before clicking or typing.",
            isBuiltIn: true
        ),
        EarthSkill(
            id: "mac-troubleshooting",
            name: "Mac Troubleshooting",
            summary: "Diagnoses permissions, app install, voice, provider, and setup problems.",
            category: .macOS,
            requiredTools: ["show_readiness", "advanced_computer_use"],
            requiredPermissions: [],
            triggerPhrases: ["not working", "buggy", "permission", "fix app"],
            instructions: "Identify the failing layer, give the quickest safe fix, and avoid technical overload.",
            isBuiltIn: true
        ),
        EarthSkill(
            id: "safe-automation",
            name: "Safe Automation",
            summary: "Plans Mac actions with confirmations and visible progress.",
            category: .automation,
            requiredTools: ["inspect_ui", "click_element", "type_text"],
            requiredPermissions: [.accessibility],
            triggerPhrases: ["control my mac", "click", "type this", "automate"],
            instructions: "Capture or inspect first, confirm before actions, pause on mouse movement, and log every step.",
            isBuiltIn: true
        )
    ]
}

struct SkillMatch: Identifiable, Equatable {
    let id = UUID()
    let skill: EarthSkill
    let score: Int
}
