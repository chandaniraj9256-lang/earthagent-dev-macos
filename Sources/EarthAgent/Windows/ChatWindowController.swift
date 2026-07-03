import AppKit
import SwiftUI

@MainActor
final class ChatWindowController {
    private let panel: NSPanel

    init(model: AppModel) {
        let size = NSSize(width: 620, height: 720)
        self.panel = NSPanel(
            contentRect: NSRect(x: 240, y: 240, width: size.width, height: size.height),
            styleMask: [.titled, .closable, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Earth Agent"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.titlebarAppearsTransparent = true
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.minSize = NSSize(width: 560, height: 620)
        panel.contentView = NSHostingView(rootView: ChatPanelView().environmentObject(model))
    }

    func toggle() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }

    func show() {
        let mouse = NSEvent.mouseLocation
        panel.setFrameOrigin(CGPoint(x: max(40, mouse.x - 230), y: max(80, mouse.y - 700)))
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
