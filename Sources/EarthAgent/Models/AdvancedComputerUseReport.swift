import Foundation

struct ComputerUseCapability: Identifiable, Equatable {
    enum State: Equatable {
        case ready
        case needsPermission
        case confirmationRequired
        case planned
    }

    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let state: State
}

struct AdvancedComputerUseReport: Equatable {
    let generatedAt: Date
    let activeApp: String
    let accessibilityTrusted: Bool
    let runningApps: [String]
    let visibleWindows: [String]
    let capabilities: [ComputerUseCapability]

    var summary: String {
        let permission = accessibilityTrusted ? "Accessibility is enabled." : "Accessibility permission is needed."
        let apps = runningApps.prefix(6).joined(separator: ", ")
        let windows = visibleWindows.prefix(4).joined(separator: "\n")
        return """
        \(permission)
        Active app: \(activeApp)
        Running apps: \(apps.isEmpty ? "No app list available" : apps)

        Visible windows:
        \(windows.isEmpty ? "No visible window list available" : windows)
        """
    }
}
