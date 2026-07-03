import Foundation

struct SocialConnectorProfile: Identifiable, Codable, Equatable {
    enum Platform: String, CaseIterable, Codable, Identifiable {
        case telegram = "Telegram"
        case whatsapp = "WhatsApp"
        case slack = "Slack"
        case discord = "Discord"
        case email = "Email"

        var id: String { rawValue }
    }

    enum Status: String, Codable, Equatable {
        case available = "Available"
        case needsSetup = "Needs setup"
        case connected = "Connected"
        case paused = "Paused"
        case planned = "Planned"
    }

    var id: String
    var platform: Platform
    var displayName: String
    var status: Status
    var isEnabled: Bool
    var webhookURL: String
    var botTokenSaved: Bool
    var allowedDestination: String
    var notes: String

    static let defaults: [SocialConnectorProfile] = [
        SocialConnectorProfile(
            id: "telegram",
            platform: .telegram,
            displayName: "Telegram",
            status: .needsSetup,
            isEnabled: false,
            webhookURL: "",
            botTokenSaved: false,
            allowedDestination: "",
            notes: "Use for remote approval prompts and task-complete notifications. Bot token stays in Keychain."
        ),
        SocialConnectorProfile(
            id: "whatsapp",
            platform: .whatsapp,
            displayName: "WhatsApp",
            status: .planned,
            isEnabled: false,
            webhookURL: "",
            botTokenSaved: false,
            allowedDestination: "",
            notes: "Requires WhatsApp Cloud API setup. Outbound messages will always require explicit permission."
        ),
        SocialConnectorProfile(
            id: "slack",
            platform: .slack,
            displayName: "Slack",
            status: .needsSetup,
            isEnabled: false,
            webhookURL: "",
            botTokenSaved: false,
            allowedDestination: "",
            notes: "Use Slack webhook or bot setup for task summaries and approvals."
        ),
        SocialConnectorProfile(
            id: "discord",
            platform: .discord,
            displayName: "Discord",
            status: .needsSetup,
            isEnabled: false,
            webhookURL: "",
            botTokenSaved: false,
            allowedDestination: "",
            notes: "Optional community/team notifications. External posting remains guarded."
        ),
        SocialConnectorProfile(
            id: "email",
            platform: .email,
            displayName: "Email",
            status: .planned,
            isEnabled: false,
            webhookURL: "",
            botTokenSaved: false,
            allowedDestination: "",
            notes: "Email delivery will require SMTP/provider setup and send confirmation."
        )
    ]
}
