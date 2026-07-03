import AppKit
import Carbon.HIToolbox

enum ComputerControlError: LocalizedError {
    case accessibilityPermissionMissing
    case blockedAction(String)
    case unsupportedShortcut(String)
    case cannotCreateKeyboardEvent
    case noFrontmostApplication
    case elementNotFound(Int)
    case elementCannotPress(Int)

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionMissing:
            return "Accessibility permission is required before Earth can inspect the browser, click, type, or press keys."
        case .blockedAction(let reason):
            return "Earth blocked this computer-control action: \(reason)"
        case .unsupportedShortcut(let shortcut):
            return "The shortcut '\(shortcut)' is not supported yet."
        case .cannotCreateKeyboardEvent:
            return "macOS did not allow Earth to create a keyboard event."
        case .noFrontmostApplication:
            return "Could not find the active app."
        case .elementNotFound(let index):
            return "Could not find UI element #\(index). Refresh visible elements and try again."
        case .elementCannotPress(let index):
            return "UI element #\(index) does not support press/click through Accessibility."
        }
    }
}

final class ComputerControlService {
    private var indexedElements: [Int: AXUIElement] = [:]

    func isAccessibilityTrusted(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func activeApplicationName() -> String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown app"
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func typeTextIntoFocusedField(_ text: String) throws {
        guard isAccessibilityTrusted() else {
            throw ComputerControlError.accessibilityPermissionMissing
        }
        if let reason = blockedTypedTextReason(text) {
            throw ComputerControlError.blockedAction(reason)
        }

        for character in text {
            try postUnicode(character)
            Thread.sleep(forTimeInterval: 0.012)
        }
    }

    func pressShortcut(_ shortcut: String) throws {
        guard isAccessibilityTrusted() else {
            throw ComputerControlError.accessibilityPermissionMissing
        }

        let normalized = shortcut
            .lowercased()
            .replacingOccurrences(of: "command", with: "cmd")
            .replacingOccurrences(of: "⌘", with: "cmd")
            .replacingOccurrences(of: "+", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map(String.init)

        if let reason = blockedShortcutReason(normalized) {
            throw ComputerControlError.blockedAction(reason)
        }

        let commandShortcuts: [String: CGKeyCode] = [
            "a": CGKeyCode(kVK_ANSI_A),
            "c": CGKeyCode(kVK_ANSI_C),
            "l": CGKeyCode(kVK_ANSI_L),
            "r": CGKeyCode(kVK_ANSI_R),
            "s": CGKeyCode(kVK_ANSI_S),
            "v": CGKeyCode(kVK_ANSI_V),
            "w": CGKeyCode(kVK_ANSI_W)
        ]

        if normalized.contains("cmd"), let key = normalized.last, let keyCode = commandShortcuts[key] {
            try postKey(keyCode, flags: .maskCommand)
            return
        }

        if normalized.contains("return") || normalized.contains("enter") {
            try postKey(CGKeyCode(kVK_Return), flags: [])
            return
        }
        if normalized.contains("escape") || normalized.contains("esc") {
            try postKey(CGKeyCode(kVK_Escape), flags: [])
            return
        }
        if normalized.contains("tab") {
            try postKey(CGKeyCode(kVK_Tab), flags: [])
            return
        }

        throw ComputerControlError.unsupportedShortcut(shortcut)
    }

    func focusApplication(named name: String) throws {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw ComputerControlError.noFrontmostApplication }
        let apps = NSWorkspace.shared.runningApplications
        guard let app = apps.first(where: {
            ($0.localizedName ?? "").localizedCaseInsensitiveContains(clean)
        }) else {
            throw ComputerControlError.noFrontmostApplication
        }
        app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }

    func runningApplicationNames(limit: Int = 20) -> [String] {
        let names = NSWorkspace.shared.runningApplications
            .compactMap(\.localizedName)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .uniquedCaseInsensitive()
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return Array(names.prefix(limit))
    }

    func visibleWindowSummaries(limit: Int = 12) -> [String] {
        guard let rawWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        let summaries = rawWindows.compactMap { window in
            let owner = window[kCGWindowOwnerName as String] as? String ?? ""
            let title = window[kCGWindowName as String] as? String ?? ""
            let layer = window[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0, !owner.isEmpty else { return nil }
            if title.isEmpty {
                return owner
            }
            return "\(owner): \(title)"
        }
        .uniquedCaseInsensitive()
        return Array(summaries.prefix(limit))
    }

    func advancedReport() -> AdvancedComputerUseReport {
        let trusted = isAccessibilityTrusted(prompt: false)
        return AdvancedComputerUseReport(
            generatedAt: Date(),
            activeApp: activeApplicationName(),
            accessibilityTrusted: trusted,
            runningApps: runningApplicationNames(),
            visibleWindows: visibleWindowSummaries(),
            capabilities: [
                ComputerUseCapability(
                    id: "inspect",
                    title: "Inspect visible UI",
                    detail: trusted ? "Can read Accessibility elements in the active app." : "Needs Accessibility permission.",
                    systemImage: "list.bullet.rectangle",
                    state: trusted ? .ready : .needsPermission
                ),
                ComputerUseCapability(
                    id: "click",
                    title: "Confirmed click",
                    detail: "Clicks only numbered elements after confirmation.",
                    systemImage: "cursorarrow.click",
                    state: trusted ? .confirmationRequired : .needsPermission
                ),
                ComputerUseCapability(
                    id: "type",
                    title: "Confirmed typing",
                    detail: "Types into the focused field after confirmation and blocks dangerous shell text.",
                    systemImage: "keyboard",
                    state: trusted ? .confirmationRequired : .needsPermission
                ),
                ComputerUseCapability(
                    id: "scroll",
                    title: "Confirmed scroll",
                    detail: "Can scroll the active app after confirmation.",
                    systemImage: "arrow.up.and.down",
                    state: trusted ? .confirmationRequired : .needsPermission
                ),
                ComputerUseCapability(
                    id: "ocr",
                    title: "Screen OCR",
                    detail: "Planned. Requires a privacy-first Screen Recording permission flow.",
                    systemImage: "text.viewfinder",
                    state: .planned
                )
            ]
        )
    }

    func scroll(direction: String) throws {
        guard isAccessibilityTrusted() else {
            throw ComputerControlError.accessibilityPermissionMissing
        }
        let normalized = direction.lowercased()
        let amount: Int32 = normalized.contains("up") ? 6 : -6
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 1,
            wheel1: amount,
            wheel2: 0,
            wheel3: 0
        ) else {
            throw ComputerControlError.cannotCreateKeyboardEvent
        }
        event.post(tap: .cghidEventTap)
    }

    func inspectVisibleElements(limit: Int = 18) throws -> [AccessibilityElementSnapshot] {
        guard isAccessibilityTrusted() else {
            throw ComputerControlError.accessibilityPermissionMissing
        }
        guard let app = NSWorkspace.shared.frontmostApplication else {
            throw ComputerControlError.noFrontmostApplication
        }

        indexedElements.removeAll()
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var collected: [(AXUIElement, AccessibilityElementSnapshot)] = []
        collectElements(from: appElement, depth: 0, maxDepth: 5, into: &collected, limit: limit)

        indexedElements = Dictionary(uniqueKeysWithValues: collected.map { ($0.1.id, $0.0) })
        return collected.map(\.1)
    }

    func clickElement(index: Int) throws {
        guard isAccessibilityTrusted() else {
            throw ComputerControlError.accessibilityPermissionMissing
        }
        guard let element = indexedElements[index] else {
            throw ComputerControlError.elementNotFound(index)
        }

        if AXUIElementPerformAction(element, kAXPressAction as CFString) == .success {
            return
        }

        if let point = centerPoint(of: element) {
            click(at: point)
            return
        }

        throw ComputerControlError.elementCannotPress(index)
    }

    private func blockedTypedTextReason(_ text: String) -> String? {
        let lowered = text.lowercased()
        let blockedFragments = [
            "curl ": "piping downloaded scripts is unsafe",
            "wget ": "piping downloaded scripts is unsafe",
            "rm -rf /": "recursive root deletion is blocked",
            "sudo rm -": "destructive sudo deletion is blocked",
            ":(){ :|:& };:": "fork-bomb text is blocked"
        ]

        if (lowered.contains("curl ") || lowered.contains("wget ")) &&
            (lowered.contains("| bash") || lowered.contains("| sh")) {
            return "download-and-run shell commands are blocked"
        }

        for (fragment, reason) in blockedFragments where lowered.contains(fragment) {
            return reason
        }
        return nil
    }

    private func blockedShortcutReason(_ keys: [String]) -> String? {
        let set = Set(keys)
        let blocked: [(Set<String>, String)] = [
            (["cmd", "shift", "q"], "log out shortcut is blocked"),
            (["cmd", "option", "shift", "q"], "force log out shortcut is blocked"),
            (["cmd", "ctrl", "q"], "lock screen shortcut is blocked"),
            (["cmd", "option", "backspace"], "force delete shortcut is blocked"),
            (["cmd", "shift", "backspace"], "empty trash shortcut is blocked")
        ]
        for item in blocked where item.0.isSubset(of: set) {
            return item.1
        }
        return nil
    }

    private func postUnicode(_ character: Character) throws {
        var utf16 = Array(String(character).utf16)
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            throw ComputerControlError.cannotCreateKeyboardEvent
        }
        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags) throws {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            throw ComputerControlError.cannotCreateKeyboardEvent
        }
        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func collectElements(
        from element: AXUIElement,
        depth: Int,
        maxDepth: Int,
        into collected: inout [(AXUIElement, AccessibilityElementSnapshot)],
        limit: Int
    ) {
        guard depth <= maxDepth, collected.count < limit else { return }

        if let snapshot = snapshot(for: element, id: collected.count + 1), isUseful(snapshot) {
            collected.append((element, snapshot))
        }

        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue) == .success,
              let children = childrenValue as? [AXUIElement] else {
            return
        }

        for child in children {
            collectElements(from: child, depth: depth + 1, maxDepth: maxDepth, into: &collected, limit: limit)
            if collected.count >= limit { break }
        }
    }

    private func snapshot(for element: AXUIElement, id: Int) -> AccessibilityElementSnapshot? {
        let role = stringAttribute(kAXRoleAttribute, from: element)
        guard !role.isEmpty else { return nil }
        let title = stringAttribute(kAXTitleAttribute, from: element)
        let value = stringAttribute(kAXValueAttribute, from: element)
        let canPress = actions(for: element).contains(kAXPressAction as String)
        return AccessibilityElementSnapshot(
            id: id,
            role: role.replacingOccurrences(of: "AX", with: ""),
            title: title,
            value: value,
            frameDescription: frameDescription(for: element),
            canPress: canPress
        )
    }

    private func isUseful(_ snapshot: AccessibilityElementSnapshot) -> Bool {
        let role = snapshot.role.lowercased()
        let hasName = !snapshot.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasName && (
            snapshot.canPress ||
            role.contains("button") ||
            role.contains("link") ||
            role.contains("textfield") ||
            role.contains("checkbox") ||
            role.contains("menuitem") ||
            role.contains("radio") ||
            role.contains("tab")
        )
    }

    private func stringAttribute(_ attribute: String, from element: AXUIElement) -> String {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return ""
        }
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return ""
    }

    private func actions(for element: AXUIElement) -> [String] {
        var names: CFArray?
        guard AXUIElementCopyActionNames(element, &names) == .success else { return [] }
        return (names as? [String]) ?? []
    }

    private func frameDescription(for element: AXUIElement) -> String {
        guard let rect = rect(of: element) else { return "unknown frame" }
        return "x:\(Int(rect.origin.x)) y:\(Int(rect.origin.y)) w:\(Int(rect.width)) h:\(Int(rect.height))"
    }

    private func centerPoint(of element: AXUIElement) -> CGPoint? {
        guard let rect = rect(of: element) else { return nil }
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    private func rect(of element: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionAX = positionValue,
              let sizeAX = sizeValue else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard CFGetTypeID(positionAX) == AXValueGetTypeID(),
              CFGetTypeID(sizeAX) == AXValueGetTypeID(),
              AXValueGetValue(positionAX as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeAX as! AXValue, .cgSize, &size) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    private func click(at point: CGPoint) {
        guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
              let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
            return
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

private extension Array where Element == String {
    func uniquedCaseInsensitive() -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for item in self {
            let key = item.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(item)
        }
        return result
    }
}
