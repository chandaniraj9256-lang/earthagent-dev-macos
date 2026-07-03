import AppKit
import Combine
import SwiftUI

@MainActor
final class AssistantPreviewWindowController {
    private enum Anchor {
        case cursor
        case earth(NSRect)
    }

    private let panel: NSPanel
    private let model: AppModel
    private var modelObserver: AnyCancellable?
    private var anchor: Anchor = .cursor

    init(model: AppModel, openFullChat: @escaping () -> Void) {
        self.model = model
        let initialSize = AssistantPreviewLayout.panelSize(showingPreview: false, hasConfirmation: false, hasAttachments: false)
        self.panel = FloatingCommandPanel(
            contentRect: NSRect(x: 280, y: 280, width: initialSize.width, height: initialSize.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.contentView = NSHostingView(
            rootView: AssistantPreviewView(openFullChat: openFullChat)
                .environmentObject(model)
        )
        modelObserver = model.objectWillChange.sink { [weak self] in
            Task { @MainActor in
                self?.refreshLayout()
            }
        }
    }

    func showAndListen() {
        anchor = .cursor
        showMinibar()
        model.startConversationMode()
    }

    func showAndListen(below earthFrame: NSRect) {
        anchor = .earth(earthFrame)
        showMinibar(below: earthFrame)
        model.startConversationMode()
    }

    func showMinibar() {
        anchor = .cursor
        refreshLayout()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showMinibar(below earthFrame: NSRect) {
        anchor = .earth(earthFrame)
        refreshLayout()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func refreshLayout() {
        let size = AssistantPreviewLayout.panelSize(
            showingPreview: model.setupNeedsAttention ||
                model.shouldShowOnboarding ||
                (!model.browserCandidates.isEmpty && model.status != .idle) ||
                (!model.taskRunSteps.isEmpty && model.status != .idle) ||
                model.isListening ||
                model.isSpeaking ||
                model.status == .thinking ||
                model.status == .working ||
                model.status == .waitingForConfirmation ||
                model.status == .failed ||
                model.status == .completed ||
                model.isConversationMode,
            hasConfirmation: model.pendingConfirmation != nil,
            hasAttachments: !model.pendingAttachments.isEmpty
        )
        switch anchor {
        case .cursor:
            positionNearCursor(size: size)
        case .earth(let earthFrame):
            positionBelowEarth(earthFrame, size: size)
        }
    }

    private func positionNearCursor(size: NSSize) {
        let mouse = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let proposedX = mouse.x - size.width / 2
        let proposedY = mouse.y - size.height - 44
        let x = min(max(screenFrame.minX + 16, proposedX), screenFrame.maxX - size.width - 16)
        let y = min(max(screenFrame.minY + 16, proposedY), screenFrame.maxY - size.height - 16)
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    private func positionBelowEarth(_ earthFrame: NSRect, size: NSSize) {
        let screenFrame = NSScreen.screens.first(where: { $0.frame.intersects(earthFrame) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let spacing: CGFloat = 8
        let proposedX = earthFrame.midX - size.width / 2
        let proposedY = earthFrame.minY - size.height - spacing
        let x = min(max(screenFrame.minX + 12, proposedX), screenFrame.maxX - size.width - 12)
        let y = max(screenFrame.minY + 12, proposedY)
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }
}

private final class FloatingCommandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
