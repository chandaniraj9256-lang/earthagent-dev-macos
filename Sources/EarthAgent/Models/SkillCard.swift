import Foundation

struct SkillCard: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let prompt: String
    let requiresFuturePermission: Bool

    static let defaults: [SkillCard] = [
        SkillCard(
            id: "summarize-file",
            title: "Summarize File",
            subtitle: "Review an upload",
            systemImage: "doc.text.magnifyingglass",
            prompt: "Summarize the file I upload and give me the key points.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "draft-message",
            title: "Draft Message",
            subtitle: "Write, don't send",
            systemImage: "square.and.pencil",
            prompt: "Draft a clear, friendly message. Do not send it.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "web-research",
            title: "Web Research",
            subtitle: "Search safely",
            systemImage: "magnifyingglass",
            prompt: "Search the web for AI automation tools.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "open-app",
            title: "Open App",
            subtitle: "Launch safely",
            systemImage: "app.dashed",
            prompt: "Open Safari.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "browser-inspect",
            title: "Inspect Browser",
            subtitle: "Read visible page UI",
            systemImage: "safari",
            prompt: "Inspect browser.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "control-status",
            title: "Control Status",
            subtitle: "Check permissions",
            systemImage: "cursorarrow.motionlines",
            prompt: "Computer control status.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "advanced-control",
            title: "Computer Use",
            subtitle: "Advanced status",
            systemImage: "macwindow.badge.plus",
            prompt: "Advanced computer use status.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "subagent-review",
            title: "Agent Swarm",
            subtitle: "30-agent review",
            systemImage: "person.3.sequence.fill",
            prompt: "Use all 30 agents to review this plan and suggest the safest next step.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "routines",
            title: "Routines",
            subtitle: "Local automations",
            systemImage: "calendar.badge.clock",
            prompt: "List routines.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "mcp-connectors",
            title: "Connectors",
            subtitle: "MCP status",
            systemImage: "point.3.connected.trianglepath.dotted",
            prompt: "MCP connector status.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "active-app",
            title: "Active App",
            subtitle: "What am I using?",
            systemImage: "macwindow",
            prompt: "What app am I using?",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "inspect-ui",
            title: "Inspect UI",
            subtitle: "List click targets",
            systemImage: "list.bullet.rectangle",
            prompt: "Inspect visible UI elements.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "type-sample",
            title: "Type Text",
            subtitle: "Focused field",
            systemImage: "keyboard",
            prompt: "Type this: Hello from Earth Agent.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "screen-help",
            title: "Explain Screen",
            subtitle: "Capture + visual answer",
            systemImage: "rectangle.and.text.magnifyingglass",
            prompt: "Look at my screen and help me understand what to do next.",
            requiresFuturePermission: false
        ),
        SkillCard(
            id: "website-plan",
            title: "Simple Website",
            subtitle: "Create local files",
            systemImage: "globe",
            prompt: "Create a simple local website for my idea.",
            requiresFuturePermission: false
        )
    ]
}
