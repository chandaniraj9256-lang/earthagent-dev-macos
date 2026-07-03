import Foundation

struct MCPConnectorProfile: Identifiable, Codable, Equatable {
    enum Transport: String, CaseIterable, Codable, Equatable {
        case stdio = "stdio"
        case sse = "sse"
        case http = "http"
    }

    enum Status: String, Codable, Equatable {
        case available = "Available"
        case enabled = "Enabled"
        case needsConfiguration = "Needs setup"
        case planned = "Planned"
        case failed = "Failed"
    }

    enum Risk: String, Codable, Equatable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }

    var id: String
    var name: String
    var subtitle: String
    var transport: Transport
    var command: String
    var endpoint: String
    var isEnabled: Bool
    var status: Status
    var risk: Risk
    var notes: String
    var availableTools: [String]?
    var enabledTools: [String]?

    static let defaults: [MCPConnectorProfile] = [
        MCPConnectorProfile(
            id: "filesystem",
            name: "Local Files",
            subtitle: "Future file/project tools",
            transport: .stdio,
            command: "mcp-server-filesystem",
            endpoint: "",
            isEnabled: false,
            status: .planned,
            risk: .medium,
            notes: "Planned. Will require folder-level permission and visible approvals before file writes.",
            availableTools: ["list_files", "read_file", "write_file"],
            enabledTools: ["list_files", "read_file"]
        ),
        MCPConnectorProfile(
            id: "linear",
            name: "Linear",
            subtitle: "Issues and product work",
            transport: .stdio,
            command: "linear-mcp",
            endpoint: "",
            isEnabled: false,
            status: .needsConfiguration,
            risk: .medium,
            notes: "Install/configure a Linear MCP server later, then enable this connector.",
            availableTools: ["find_issues", "get_issue", "create_issue"],
            enabledTools: ["find_issues", "get_issue"]
        ),
        MCPConnectorProfile(
            id: "github",
            name: "GitHub",
            subtitle: "Repos, issues, pull requests",
            transport: .stdio,
            command: "github-mcp-server",
            endpoint: "",
            isEnabled: false,
            status: .needsConfiguration,
            risk: .high,
            notes: "High-risk connector. Earth should require confirmation before code, issue, or PR changes.",
            availableTools: ["search_repositories", "get_issue", "create_issue", "create_pull_request"],
            enabledTools: ["search_repositories", "get_issue"]
        ),
        MCPConnectorProfile(
            id: "n8n",
            name: "n8n",
            subtitle: "Workflow automation",
            transport: .http,
            command: "",
            endpoint: "http://localhost:5678/mcp",
            isEnabled: false,
            status: .needsConfiguration,
            risk: .high,
            notes: "Use only with explicit workflow permissions. External automations should never run silently.",
            availableTools: ["list_workflows", "get_workflow", "trigger_workflow"],
            enabledTools: ["list_workflows", "get_workflow"]
        ),
        MCPConnectorProfile(
            id: "custom-local",
            name: "Custom Local MCP",
            subtitle: "Bring your own local server",
            transport: .http,
            command: "",
            endpoint: "http://localhost:3000/mcp",
            isEnabled: false,
            status: .needsConfiguration,
            risk: .medium,
            notes: "Foundation connector for local MCP servers. Protocol execution will be wired in a later layer.",
            availableTools: [],
            enabledTools: []
        )
    ]
}
