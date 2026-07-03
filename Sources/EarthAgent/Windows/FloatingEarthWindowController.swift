import AppKit
import SwiftUI

@MainActor
final class FloatingEarthWindowController {
    private let panel: NSPanel
    private var timer: Timer?
    private var currentOrigin = CGPoint(x: 300, y: 300)
    private let size = NSSize(width: 72, height: 72)

    init(model: AppModel, onClick: @escaping (NSRect) -> Void, onDoubleClick: @escaping (NSRect) -> Void) {
        self.panel = NSPanel(
            contentRect: NSRect(origin: currentOrigin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.contentView = ClickableHostingView(
            rootView: EarthIconView(model: model),
            onClick: { [weak panel] in
                onClick(panel?.frame ?? NSRect(origin: self.currentOrigin, size: self.size))
            },
            onDoubleClick: { [weak panel] in
                onDoubleClick(panel?.frame ?? NSRect(origin: self.currentOrigin, size: self.size))
            }
        )
    }

    func show() {
        let mouse = NSEvent.mouseLocation
        currentOrigin = clampedOrigin(CGPoint(x: mouse.x + 42, y: mouse.y - 86))
        panel.setFrameOrigin(currentOrigin)
        panel.orderFrontRegardless()
        startFollowingCursor()
    }

    private func startFollowingCursor() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePosition()
            }
        }
    }

    private func updatePosition() {
        let mouse = NSEvent.mouseLocation
        let center = CGPoint(x: currentOrigin.x + size.width / 2, y: currentOrigin.y + size.height / 2)
        let distance = hypot(mouse.x - center.x, mouse.y - center.y)

        // Let the user catch the icon. It follows when far away and rests when the pointer is close.
        guard distance > 120 else { return }

        let target = CGPoint(x: mouse.x + 42, y: mouse.y - 86)
        currentOrigin.x += (target.x - currentOrigin.x) * 0.07
        currentOrigin.y += (target.y - currentOrigin.y) * 0.07
        currentOrigin = clampedOrigin(currentOrigin)
        panel.setFrameOrigin(currentOrigin)
    }

    private func clampedOrigin(_ origin: CGPoint) -> CGPoint {
        let screenFrame = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return CGPoint(
            x: min(max(screenFrame.minX + 8, origin.x), screenFrame.maxX - size.width - 8),
            y: min(max(screenFrame.minY + 8, origin.y), screenFrame.maxY - size.height - 8)
        )
    }
}

private final class ClickableHostingView<Content: View>: NSHostingView<Content> {
    private let onClick: () -> Void
    private let onDoubleClick: () -> Void

    required init(rootView: Content) {
        self.onClick = {}
        self.onDoubleClick = {}
        super.init(rootView: rootView)
    }

    init(rootView: Content, onClick: @escaping () -> Void, onDoubleClick: @escaping () -> Void) {
        self.onClick = onClick
        self.onDoubleClick = onDoubleClick
        super.init(rootView: rootView)
    }

    @MainActor
    @preconcurrency required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 {
            onDoubleClick()
        } else {
            onClick()
        }
    }
}
