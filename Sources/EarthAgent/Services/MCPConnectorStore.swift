import Foundation

final class MCPConnectorStore {
    private let defaultsKey = "earth-agent-mcp-connectors-v1"

    func load() -> [MCPConnectorProfile] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([MCPConnectorProfile].self, from: data) else {
            return MCPConnectorProfile.defaults
        }
        return mergeSaved(decoded)
    }

    func save(_ connectors: [MCPConnectorProfile]) {
        guard let data = try? JSONEncoder().encode(connectors) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func mergeSaved(_ saved: [MCPConnectorProfile]) -> [MCPConnectorProfile] {
        let savedByID = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
        var merged = MCPConnectorProfile.defaults.map { fallback in
            savedByID[fallback.id] ?? fallback
        }
        let custom = saved.filter { savedItem in
            !MCPConnectorProfile.defaults.contains(where: { $0.id == savedItem.id })
        }
        merged.append(contentsOf: custom)
        return merged
    }
}

final class MCPConnectorService {
    func toggle(_ connector: MCPConnectorProfile) -> MCPConnectorProfile {
        var copy = connector
        copy.isEnabled.toggle()
        copy.status = copy.isEnabled ? validationStatus(for: copy) : .available
        return copy
    }

    func validationStatus(for connector: MCPConnectorProfile) -> MCPConnectorProfile.Status {
        switch connector.transport {
        case .stdio:
            return connector.command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? .needsConfiguration
                : .enabled
        case .http, .sse:
            guard URL(string: connector.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)) != nil else {
                return .needsConfiguration
            }
            return .enabled
        }
    }

    func statusReport(connectors: [MCPConnectorProfile]) -> String {
        let enabled = connectors.filter(\.isEnabled)
        let planned = connectors.filter { $0.status == .planned }
        let available = enabled.isEmpty
            ? "No MCP connectors are enabled yet."
            : enabled.map { "- \($0.name): \($0.transport.rawValue), risk \($0.risk.rawValue)" }.joined(separator: "\n")
        return """
        MCP connector foundation is installed.

        Enabled connectors:
        \(available)

        Planned connectors visible in Settings: \(planned.map(\.name).joined(separator: ", "))

        Earth will still ask before any connector can read, write, post, change accounts, or trigger external workflows.
        """
    }
}
