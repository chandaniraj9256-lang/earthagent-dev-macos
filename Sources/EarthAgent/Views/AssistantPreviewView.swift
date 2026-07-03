import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum AssistantPreviewLayout {
    static let barWidth: CGFloat = 470
    static let barHeight: CGFloat = 54
    static let bubbleWidth: CGFloat = 410
    static let horizontalPadding: CGFloat = 10
    static let verticalPadding: CGFloat = 10
    static let spacing: CGFloat = 8
    static let previewHeight: CGFloat = 118
    static let confirmationPreviewHeight: CGFloat = 146
    static let attachmentTrayHeight: CGFloat = 44

    static func panelSize(showingPreview: Bool, hasConfirmation: Bool, hasAttachments: Bool) -> NSSize {
        let preview = showingPreview ? (hasConfirmation ? confirmationPreviewHeight : previewHeight) + spacing : 0
        let attachments = hasAttachments ? attachmentTrayHeight + spacing : 0
        let height = verticalPadding * 2 + barHeight + preview + attachments
        let width = horizontalPadding * 2 + barWidth
        return NSSize(width: width, height: height)
    }
}

struct AssistantPreviewView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var isInputFocused: Bool
    @State private var isDropTargeted = false
    let openFullChat: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if shouldShowPreview {
                EarthMessageBubble(
                    title: previewTitle,
                    text: previewText,
                    status: model.status,
                    showsTyping: showsTypingIndicator,
                    hasConfirmation: model.pendingConfirmation != nil,
                    onCancel: { model.cancelPendingTask() },
                    onConfirm: { model.confirmPendingTask() },
                    onStop: { model.stopAll() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if hasAttachments {
                MiniAttachmentTray()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    EarthPulseIcon(status: model.status)
                        .frame(width: 32, height: 32)

                    Circle()
                        .fill(statusColor)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .offset(x: 1, y: 1)
                }
                .accessibilityLabel("Earth status")

                MiniBarIconButton(
                    systemImage: "plus",
                    isActive: false,
                    tint: .black.opacity(0.74),
                    help: "Attach photos, videos, or files"
                ) {
                    model.chooseAttachments()
                }

                TextField("Ask Earth Agent", text: $model.typedMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.black)
                    .tint(.blue)
                    .lineLimit(1...2)
                    .focused($isInputFocused)
                    .onSubmit {
                        model.sendTypedMessage()
                    }

                MiniBarIconButton(
                    systemImage: primaryActionIcon,
                    isActive: primaryActionIsActive,
                    tint: primaryActionTint,
                    help: primaryActionHelp
                ) {
                    performPrimaryAction()
                }

                MiniBarIconButton(
                    systemImage: model.isConversationMode ? "stop.fill" : "waveform",
                    isActive: model.isConversationMode,
                    tint: model.isConversationMode ? .red : .blue,
                    help: model.isConversationMode ? "Stop live conversation" : "Start live conversation"
                ) {
                    model.toggleConversationMode()
                }

                MiniBarIconButton(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    isActive: false,
                    tint: .black.opacity(0.74),
                    help: "Open full Earth Agent"
                ) {
                    openFullChat()
                }

                MiniBarIconButton(
                    systemImage: "stop.fill",
                    isActive: true,
                    tint: .red,
                    help: "Emergency stop"
                ) {
                    model.stopAll()
                }
            }
            .padding(.horizontal, 14)
            .frame(width: AssistantPreviewLayout.barWidth, height: AssistantPreviewLayout.barHeight)
            .background(
                Capsule()
                    .fill(.white.opacity(0.96))
                    .overlay(Capsule().stroke(.black.opacity(0.10), lineWidth: 1))
                    .shadow(color: .black.opacity(0.16), radius: 14, y: 7)
            )
        }
            .padding(.horizontal, AssistantPreviewLayout.horizontalPadding)
        .padding(.vertical, AssistantPreviewLayout.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : .clear)
        )
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
            }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            handleFileDrop(providers)
        }
        .onAppear {
            isInputFocused = true
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.86), value: shouldShowPreview)
        .animation(.spring(response: 0.25, dampingFraction: 0.86), value: hasAttachments)
    }

    private var statusColor: Color {
        switch model.status {
        case .idle, .completed:
            return .green
        case .listening:
            return .mint
        case .thinking, .working:
            return .blue
        case .waitingForConfirmation:
            return .orange
        case .failed, .stopped:
            return .red
        case .paused:
            return .yellow
        }
    }

    private var shouldShowPreview: Bool {
        model.setupNeedsAttention ||
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
            model.isConversationMode
    }

    private var hasAttachments: Bool {
        !model.pendingAttachments.isEmpty
    }

    private var hasTypedInput: Bool {
        !model.typedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var readyToSend: Bool {
        hasTypedInput || hasAttachments
    }

    private var previewTitle: String {
        if model.isConversationMode || model.isListening || model.isSpeaking {
            return model.voiceTurnState.shortLabel
        }
        if !model.browserCandidates.isEmpty && model.status == .completed { return "Found \(model.browserCandidates.count) results" }
        if model.shouldShowOnboarding && model.status == .idle { return "Earth is ready to set up" }
        if model.setupNeedsAttention && model.status == .idle { return "Setup needed" }
        if model.isConversationMode && model.isListening { return "Conversation mode" }
        if model.isListening { return "Dictating" }
        if model.isSpeaking { return "Earth is speaking" }
        if model.currentActivity != nil { return "Working" }
        return model.status.rawValue
    }

    private var showsTypingIndicator: Bool {
        model.status == .thinking ||
            model.status == .working ||
            model.isSpeaking ||
            (model.isListening && model.typedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var previewText: String {
        if model.isConversationMode || model.isListening || model.isSpeaking {
            if model.isListening && !model.typedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return model.typedMessage
            }
            return model.voiceHint
        }
        if model.setupNeedsAttention && model.status == .idle {
            return "Click +, open Settings, save an API key, then press Test. I can open websites now, but AI answers need setup."
        }
        if !model.browserCandidates.isEmpty {
            let first = model.browserCandidates[0]
            return "\(first.summary). Say open result 1, or click element \(first.elementID) after confirmation."
        }
        if let running = model.taskRunSteps.first(where: { $0.state == .running || $0.state == .pending }) {
            return running.title
        }
        if model.isListening {
            return model.typedMessage.isEmpty ? "Listening. Speak naturally." : model.typedMessage
        }
        if let activity = model.currentActivity {
            return activity
        }
        if let pending = model.pendingConfirmation {
            return pending.explanation
        }
        if let lastAssistant = model.messages.last(where: { $0.role == .assistant }) {
            return lastAssistant.content
        }
        return "Ask me anything, or use conversation mode for a back-and-forth voice chat."
    }

    private var primaryActionIcon: String {
        if readyToSend && !model.isListening {
            return "paperplane.fill"
        }
        if model.isListening && !model.isConversationMode {
            return "paperplane.fill"
        }
        return "mic.fill"
    }

    private var primaryActionIsActive: Bool {
        readyToSend || (model.isListening && !model.isConversationMode)
    }

    private var primaryActionTint: Color {
        primaryActionIsActive ? .blue : .blue
    }

    private var primaryActionHelp: String {
        if readyToSend && !model.isListening {
            return "Send"
        }
        if model.isListening && !model.isConversationMode {
            return "Send voice"
        }
        return "Speak into the text field"
    }

    private func performPrimaryAction() {
        if readyToSend && !model.isListening {
            model.sendTypedMessage()
            return
        }
        if model.isListening && !model.isConversationMode {
            model.stopListeningAndSend()
            return
        }
        model.toggleDictation()
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        var didAccept = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            didAccept = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let url = fileURL(from: item) else { return }
                Task { @MainActor in
                    model.attachFiles([url])
                }
            }
        }
        return didAccept
    }

    private func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        if let string = item as? String {
            return URL(string: string)
        }
        return nil
    }
}

private struct MiniBarIconButton: View {
    let systemImage: String
    let isActive: Bool
    let tint: Color
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isActive ? .white : tint)
                .frame(width: 32, height: 32)
                .background(isActive ? tint : Color.black.opacity(0.055))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct EarthMessageBubble: View {
    let title: String
    let text: String
    let status: AppStatus
    let showsTyping: Bool
    let hasConfirmation: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            EarthPulseIcon(status: status)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("Earth")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.64))
                    if showsTyping {
                        TypingDots()
                    }
                }

                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(3)
                    .foregroundStyle(.white)

                if hasConfirmation {
                    HStack(spacing: 8) {
                        Button("Cancel", action: onCancel)
                            .buttonStyle(MiniPreviewActionStyle(isPrimary: false))

                        Button("Confirm", action: onConfirm)
                            .buttonStyle(MiniPreviewActionStyle(isPrimary: true))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 350, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.black.opacity(0.84))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .overlay(alignment: .bottomLeading) {
                MessageTail()
                    .fill(.black.opacity(0.84))
                    .frame(width: 14, height: 12)
                    .offset(x: -5, y: -3)
            }

            Button(action: onStop) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.85))
            .background(.black.opacity(0.5))
            .clipShape(Circle())
            .help("Stop")
        }
        .frame(width: AssistantPreviewLayout.bubbleWidth, alignment: .leading)
    }
}

private struct MiniAttachmentTray: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.pendingAttachments) { attachment in
                    MiniAttachmentChip(attachment: attachment) {
                        model.removePendingAttachment(attachment)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(width: AssistantPreviewLayout.barWidth, height: AssistantPreviewLayout.attachmentTrayHeight)
    }
}

private struct MiniAttachmentChip: View {
    let attachment: ChatAttachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(attachment.displaySize)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .background(Color.black.opacity(0.06))
            .clipShape(Circle())
            .help("Remove attachment")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .onTapGesture {
            NSWorkspace.shared.activateFileViewerSelecting([attachment.url])
        }
    }

    private var icon: String {
        switch attachment.kind {
        case .photo: "photo.fill"
        case .video: "video.fill"
        case .document: "doc.text.fill"
        case .file: "doc.fill"
        }
    }

    private var color: Color {
        switch attachment.kind {
        case .photo: .green
        case .video: .purple
        case .document: .blue
        case .file: .secondary
        }
    }
}

private struct TypingDots: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.32)) { context in
            let phase = Int(context.date.timeIntervalSinceReferenceDate / 0.32) % 3
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(.white.opacity(index == phase ? 0.95 : 0.35))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(width: 20, height: 8)
    }
}

private struct MessageTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control1: CGPoint(x: rect.midX, y: rect.midY),
            control2: CGPoint(x: rect.minX + 2, y: rect.maxY - 2)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 2))
        path.closeSubpath()
        return path
    }
}

private struct MiniPreviewActionStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(isPrimary ? Color.blue.opacity(0.95) : Color.white.opacity(0.14))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

private struct EarthPulseIcon: View {
    let status: AppStatus

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.cyan, .blue, .indigo], center: .topLeading, startRadius: 3, endRadius: 24))
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
            Circle()
                .stroke(ringColor.opacity(0.95), lineWidth: 2)
                .padding(1)
        }
        .shadow(color: ringColor.opacity(0.35), radius: 10)
    }

    private var ringColor: Color {
        switch status {
        case .listening:
            return .green
        case .thinking, .working:
            return .yellow
        case .waitingForConfirmation:
            return .orange
        case .failed, .stopped:
            return .red
        default:
            return .white
        }
    }
}
