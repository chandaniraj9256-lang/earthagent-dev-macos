import Foundation

struct AgentToolDescriptor: Identifiable, Equatable {
    enum Permission: String, CaseIterable, Codable, Equatable {
        case none = "No permission"
        case aiProvider = "AI provider"
        case keychain = "Keychain"
        case microphone = "Microphone"
        case speech = "Speech Recognition"
        case screenRecording = "Screen Recording"
        case accessibility = "Accessibility"
        case localFiles = "Local files"
        case externalAccount = "External account"
    }

    enum ConfirmationPolicy: String, CaseIterable, Codable, Equatable {
        case never = "No confirmation"
        case beforeAction = "Before action"
        case beforeExternalAction = "Before external action"
        case always = "Always confirm"
    }

    let id: String
    let title: String
    let summary: String
    let toolset: String
    let risk: AgentTask.RiskLevel
    let permission: Permission
    let confirmationPolicy: ConfirmationPolicy
    let isEnabled: Bool
    let status: String
}

enum AgentToolCatalog {
    static func descriptors(
        hasProvider: Bool,
        accessibilityReady: Bool,
        screenRecordingReady: Bool,
        mcpEnabledCount: Int,
        socialEnabledCount: Int
    ) -> [AgentToolDescriptor] {
        [
            AgentToolDescriptor(
                id: "chat_answer",
                title: "Answer in Chat",
                summary: "Responds with text using the selected AI model.",
                toolset: "Core",
                risk: .low,
                permission: .aiProvider,
                confirmationPolicy: .never,
                isEnabled: hasProvider,
                status: hasProvider ? "Ready" : "Add provider"
            ),
            AgentToolDescriptor(
                id: "open_app",
                title: "Open App",
                summary: "Launches or brings forward a Mac app.",
                toolset: "Mac",
                risk: .medium,
                permission: .none,
                confirmationPolicy: .beforeAction,
                isEnabled: true,
                status: "Ready"
            ),
            AgentToolDescriptor(
                id: "search_web",
                title: "Search Web",
                summary: "Opens a browser search and can inspect visible results.",
                toolset: "Browser",
                risk: .medium,
                permission: .none,
                confirmationPolicy: .beforeAction,
                isEnabled: true,
                status: "Ready"
            ),
            AgentToolDescriptor(
                id: "inspect_ui",
                title: "Inspect UI",
                summary: "Reads visible Accessibility elements in the focused app.",
                toolset: "Computer Use",
                risk: .low,
                permission: .accessibility,
                confirmationPolicy: .never,
                isEnabled: accessibilityReady,
                status: accessibilityReady ? "Ready" : "Needs Accessibility"
            ),
            AgentToolDescriptor(
                id: "click_element",
                title: "Click Element",
                summary: "Clicks a numbered visible element after confirmation.",
                toolset: "Computer Use",
                risk: .high,
                permission: .accessibility,
                confirmationPolicy: .always,
                isEnabled: accessibilityReady,
                status: accessibilityReady ? "Ready" : "Needs Accessibility"
            ),
            AgentToolDescriptor(
                id: "type_text",
                title: "Type Text",
                summary: "Types user-approved text into the focused field.",
                toolset: "Computer Use",
                risk: .high,
                permission: .accessibility,
                confirmationPolicy: .always,
                isEnabled: accessibilityReady,
                status: accessibilityReady ? "Ready" : "Needs Accessibility"
            ),
            AgentToolDescriptor(
                id: "look_at_screen",
                title: "Look At Screen",
                summary: "Captures the screen and asks a vision-capable model to explain it.",
                toolset: "Vision",
                risk: .medium,
                permission: .screenRecording,
                confirmationPolicy: .beforeAction,
                isEnabled: screenRecordingReady && hasProvider,
                status: screenRecordingReady ? "Ready" : "Needs Screen Recording"
            ),
            AgentToolDescriptor(
                id: "agent_swarm",
                title: "Agent Swarm",
                summary: "Runs specialist agents in parallel and synthesizes the result.",
                toolset: "Agents",
                risk: .low,
                permission: .aiProvider,
                confirmationPolicy: .never,
                isEnabled: hasProvider,
                status: hasProvider ? "Ready" : "Add provider"
            ),
            AgentToolDescriptor(
                id: "mcp_connectors",
                title: "MCP Connectors",
                summary: "Routes future external tool calls through enabled MCP connectors.",
                toolset: "Connectors",
                risk: mcpEnabledCount > 0 ? .high : .medium,
                permission: .externalAccount,
                confirmationPolicy: .beforeExternalAction,
                isEnabled: mcpEnabledCount > 0,
                status: mcpEnabledCount == 0 ? "No connector enabled" : "\(mcpEnabledCount) enabled"
            ),
            AgentToolDescriptor(
                id: "social_connectors",
                title: "Social Connectors",
                summary: "Prepares Telegram, WhatsApp, and Slack notification/approval channels.",
                toolset: "Social",
                risk: .high,
                permission: .externalAccount,
                confirmationPolicy: .always,
                isEnabled: socialEnabledCount > 0,
                status: socialEnabledCount == 0 ? "No social account connected" : "\(socialEnabledCount) connected"
            )
        ]
    }
}
