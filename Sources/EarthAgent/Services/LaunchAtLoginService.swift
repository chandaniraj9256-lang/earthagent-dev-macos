import Foundation
import ServiceManagement

final class LaunchAtLoginService {
    func status() -> SMAppService.Status {
        SMAppService.mainApp.status
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    func statusText() -> String {
        switch status() {
        case .enabled:
            return "Earth Agent will open automatically when you log in."
        case .notRegistered:
            return "Earth Agent is not set to open at login."
        case .requiresApproval:
            return "macOS needs approval in System Settings > General > Login Items."
        case .notFound:
            return "Install Earth Agent in Applications before enabling login startup."
        @unknown default:
            return "Login item status is unknown."
        }
    }
}
