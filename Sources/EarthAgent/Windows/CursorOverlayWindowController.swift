import AppKit
import SwiftUI

@MainActor
final class CursorOverlayWindowController {
    private let panel: NSPanel
    private var timer: Timer?
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
        self.panel = NSPanel(
            contentRect: NSRect(x: 300, y: 300, width: 34, height: 34),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.ignoresMouseEvents = true
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.contentView = NSHostingView(rootView: SecondCursorView().environmentObject(model))
    }

    func show() {
        panel.orderFrontRegardless()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sync()
            }
        }
    }

    private func sync() {
        if model.aiCursorVisible {
            model.pauseIfUserMovedMouse()
            panel.orderFrontRegardless()
            panel.alphaValue = 1
            panel.setFrameOrigin(CGPoint(x: model.aiCursorPosition.x, y: model.aiCursorPosition.y))
        } else {
            panel.alphaValue = 0
        }
    }
}
