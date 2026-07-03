import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingEarth: FloatingEarthWindowController?
    private var chatWindow: ChatWindowController?
    private var previewWindow: AssistantPreviewWindowController?
    private var cursorOverlay: CursorOverlayWindowController?
    private var services: AppServices?
    private var statusItem: NSStatusItem?
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let services = AppServices()
        self.services = services

        let chatWindow = ChatWindowController(model: services.model)
        self.chatWindow = chatWindow

        let previewWindow = AssistantPreviewWindowController(model: services.model) {
            chatWindow.show()
        }
        self.previewWindow = previewWindow

        let cursorOverlay = CursorOverlayWindowController(model: services.model)
        self.cursorOverlay = cursorOverlay

        let floatingEarth = FloatingEarthWindowController(
            model: services.model,
            onClick: { earthFrame in
                previewWindow.showMinibar(below: earthFrame)
            },
            onDoubleClick: { earthFrame in
                previewWindow.showAndListen(below: earthFrame)
            }
        )
        self.floatingEarth = floatingEarth

        floatingEarth.show()
        cursorOverlay.show()
        installMenuBarItem(chatWindow: chatWindow)
        installKeyboardShortcuts()
        services.model.appendLog("Earth Agent launched.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
        }
        services?.model.appendLog("Earth Agent closed.")
    }

    private func installMenuBarItem(chatWindow: ChatWindowController) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "🌎"
        item.button?.toolTip = "Earth Agent"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Minibar", action: #selector(openMinibarFromMenu), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Start Listening", action: #selector(talkFromMenu), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "Look at Screen", action: #selector(lookAtScreenFromMenu), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Open Chat", action: #selector(openChatFromMenu), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Earth Agent", action: #selector(quitFromMenu), keyEquivalent: "q"))
        item.menu = menu

        self.statusItem = item
    }

    @objc private func talkFromMenu() {
        previewWindow?.showAndListen()
    }

    @objc private func openMinibarFromMenu() {
        previewWindow?.showMinibar()
    }

    @objc private func openChatFromMenu() {
        chatWindow?.show()
    }

    @objc private func lookAtScreenFromMenu() {
        previewWindow?.showMinibar()
        services?.model.submitUserText("Look at my screen and help me understand what to do next.")
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }

    private func installKeyboardShortcuts() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleShortcut(event) ? nil : event
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                _ = self?.handleShortcut(event)
            }
        }

        services?.model.shortcutStatus = "Shortcuts ready: Control-Option-Space talk/stop, Control-Option-M minibar, Control-Option-L look."
        services?.model.appendLog("Keyboard shortcuts installed.")
    }

    private func handleShortcut(_ event: NSEvent) -> Bool {
        let required: NSEvent.ModifierFlags = [.control, .option]
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.isSuperset(of: required) else { return false }

        switch event.keyCode {
        case 49:
            toggleTalkShortcut()
            return true
        case 46:
            openMinibarFromMenu()
            services?.model.shortcutStatus = "Opened minibar with Control-Option-M."
            return true
        case 37:
            lookAtScreenFromMenu()
            services?.model.shortcutStatus = "Captured screen command with Control-Option-L."
            return true
        default:
            return false
        }
    }

    private func toggleTalkShortcut() {
        guard let model = services?.model else { return }
        if model.isConversationMode || model.isListening || model.isSpeaking {
            model.stopAll()
            previewWindow?.showMinibar()
            model.shortcutStatus = "Stopped Earth with Control-Option-Space."
        } else {
            previewWindow?.showAndListen()
            model.shortcutStatus = "Started listening with Control-Option-Space."
        }
    }
}
