import AppKit

enum AutomationError: LocalizedError {
    case appNotFound(String)

    var errorDescription: String? {
        switch self {
        case .appNotFound(let name):
            return "Could not find the app named \(name)."
        }
    }
}

final class AutomationService {
    func openApplication(named name: String) throws {
        let workspace = NSWorkspace.shared
        guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier(for: name)) ?? fallbackApplicationURL(named: name) else {
            throw AutomationError.appNotFound(name)
        }
        workspace.open(appURL)
    }

    func openWebsite(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func isAccessibilityTrusted() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func bundleIdentifier(for appName: String) -> String {
        switch appName.lowercased() {
        case "google chrome", "chrome":
            return "com.google.Chrome"
        case "safari":
            return "com.apple.Safari"
        default:
            return appName
        }
    }

    private func fallbackApplicationURL(named name: String) -> URL? {
        let appName = name.hasSuffix(".app") ? name : "\(name).app"
        let candidates = [
            "/Applications/\(appName)",
            "/System/Applications/\(appName)",
            "/Applications/Utilities/\(appName)",
            "\(NSHomeDirectory())/Applications/\(appName)"
        ]
        return candidates
            .map(URL.init(fileURLWithPath:))
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }
}
