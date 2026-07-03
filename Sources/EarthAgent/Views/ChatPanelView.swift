import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ChatPanelView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedTab: PanelTab = .chat

    var body: some View {
        HStack(spacing: 0) {
            EarthSidebar(selectedTab: $selectedTab)

            Divider().opacity(0.55)

            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider().opacity(0.55)

            EarthInspector(selectedTab: $selectedTab)
        }
        .frame(minWidth: 1040, minHeight: 680)
        .background(appBackground)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .chat:
            ChatView(selectedTab: $selectedTab)
        case .tasks:
            TasksView()
        case .agents:
            AgentsView()
        case .memory:
            MemoryView()
        case .settings:
            SettingsView()
        case .safety:
            SafetyView()
        case .logs:
            LogsView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                EarthMiniIcon(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Earth Agent")
                        .font(.system(size: 20, weight: .semibold))
                    Text(headerSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                StatusPill(status: model.status)

                Button {
                    model.stopAll()
                } label: {
                    Image(systemName: "stop.fill")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .help("Emergency stop")
            }

            ReadinessStrip()
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.accentColor.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(PanelTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.title, systemImage: tab.systemImage)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                    .background(selectedTab == tab ? Color.accentColor : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.74))
    }

    private var headerSubtitle: String {
        if let activity = model.currentActivity {
            return activity
        }
        return "\(model.providerConfig.providerName) • \(model.providerConfig.modelName)"
    }

    private var appBackground: some View {
        Color(nsColor: .windowBackgroundColor)
    }
}

private enum PanelTab: CaseIterable, Identifiable {
    case chat
    case tasks
    case agents
    case memory
    case settings
    case safety
    case logs

    var id: Self { self }

    var title: String {
        switch self {
        case .chat: "Chat"
        case .tasks: "Tasks"
        case .agents: "Agents"
        case .memory: "Memory"
        case .settings: "Settings"
        case .safety: "Safety"
        case .logs: "Logs"
        }
    }

    var systemImage: String {
        switch self {
        case .chat: "message.fill"
        case .tasks: "checklist"
        case .agents: "sparkles.square.filled.on.square"
        case .memory: "brain.head.profile"
        case .settings: "slider.horizontal.3"
        case .safety: "hand.raised.fill"
        case .logs: "list.clipboard"
        }
    }
}

private struct EarthSidebar: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selectedTab: PanelTab

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                EarthMiniIcon(size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Earth Agent")
                        .font(.headline.weight(.semibold))
                    Text("Desktop assistant")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 20)

            StatusPill(status: model.status)

            VStack(spacing: 5) {
                ForEach(PanelTab.allCases) { tab in
                    SidebarButton(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Label(model.voiceTurnState.shortLabel, systemImage: voiceIcon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(model.isConversationMode ? Color.accentColor : .secondary)
                    .lineLimit(1)

                Button {
                    model.pauseTask()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    model.stopAll()
                } label: {
                    Label("Emergency stop", systemImage: "stop.fill")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(width: 180, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.70))
    }

    private var voiceIcon: String {
        switch model.voiceTurnState {
        case .idle: "speaker.wave.1"
        case .listening: "mic.fill"
        case .processing: "brain.head.profile"
        case .speaking: "speaker.wave.2.fill"
        case .interrupted: "hand.raised.fill"
        case .paused: "pause.circle.fill"
        case .stopped: "stop.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
}

private struct SidebarButton: View {
    let tab: PanelTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(tab.title, systemImage: tab.systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(isSelected ? Color.accentColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct EarthInspector: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selectedTab: PanelTab

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Now")
                            .font(.title3.weight(.semibold))
                        Text(model.currentActivity ?? "Ready when you are.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    StatusPill(status: model.status)
                }

                LaunchReadinessCompactCard()

                SetupChecklistPanel()

                ShortcutPanel()

                if let pending = model.pendingConfirmation {
                    InspectorConfirmationCard(task: pending)
                }

                if let task = model.latestPlan {
                    InspectorPlanCard(task: task)
                } else {
                    QuietPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task plan")
                                .font(.headline)
                            Text("Ask Earth to do something and the plan will appear here before risky steps.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                InspectorTimeline()

                QuietPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Suggested next actions")
                            .font(.headline)

                        SuggestedActionButton(title: "Open settings", icon: "slider.horizontal.3") {
                            selectedTab = .settings
                        }

                        SuggestedActionButton(title: "Review safety", icon: "hand.raised.fill") {
                            selectedTab = .safety
                        }

                        SuggestedActionButton(title: "View logs", icon: "list.clipboard") {
                            selectedTab = .logs
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.76))
    }
}

private struct LaunchReadinessCompactCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let summary = model.launchReadiness
        QuietPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Launch readiness")
                            .font(.headline)
                        Text(summary.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(summary.score)%")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(readinessColor(summary.score))
                }

                ProgressView(value: Double(summary.score), total: 100)
                    .tint(readinessColor(summary.score))

                Text("\(summary.readyCount)/\(summary.totalCount) checks ready")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct LaunchReadinessDetailCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let summary = model.launchReadiness
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    SectionHeader(title: "Launch Readiness", subtitle: summary.detail)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(summary.score)%")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(readinessColor(summary.score))
                        Text(summary.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: Double(summary.score), total: 100)
                    .tint(readinessColor(summary.score))

                HStack {
                    Button {
                        model.exportDiagnosticsReport()
                    } label: {
                        Label("Export Diagnostics", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)

                    Text(model.diagnosticsExportStatus)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], spacing: 10) {
                    ForEach(summary.items) { item in
                        LaunchReadinessRow(item: item)
                    }
                }
            }
        }
    }
}

private struct LaunchReadinessRow: View {
    let item: LaunchReadinessItem

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(item.category.rawValue)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Text(item.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var icon: String {
        switch item.state {
        case .ready: "checkmark.circle.fill"
        case .warning: "exclamationmark.circle.fill"
        case .actionNeeded: "xmark.circle.fill"
        }
    }

    private var color: Color {
        switch item.state {
        case .ready: .green
        case .warning: .orange
        case .actionNeeded: .red
        }
    }
}

private func readinessColor(_ score: Int) -> Color {
    if score >= 85 { return .green }
    if score >= 65 { return .orange }
    return .red
}

private struct ShortcutPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Quick access")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "keyboard")
                        .foregroundStyle(.secondary)
                }

                ShortcutRow(keys: "⌃ ⌥ Space", text: "Talk or stop")
                ShortcutRow(keys: "⌃ ⌥ M", text: "Open minibar")
                ShortcutRow(keys: "⌃ ⌥ L", text: "Look at screen")

                Text(model.shortcutStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

private struct ShortcutRow: View {
    let keys: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(keys)
                .font(.caption.monospaced().weight(.semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }
}

private struct SetupChecklistPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Setup checklist")
                        .font(.headline)
                    Spacer()
                    Text("\(readyCount)/6")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ForEach(items) { item in
                    ChecklistRow(item: item)
                }
            }
        }
    }

    private var readyCount: Int {
        items.filter { $0.state == .ready }.count
    }

    private var items: [ReadinessItem] {
        [
            ReadinessItem(
                id: "ai",
                title: "AI provider connected",
                detail: model.isProviderConnected ? model.providerConfig.providerName : "Test your provider in Settings",
                state: model.isProviderConnected ? .ready : .warning
            ),
            ReadinessItem(
                id: "model",
                title: "Model selected",
                detail: model.providerConfig.modelName.isEmpty ? "Choose a model" : model.providerConfig.modelName,
                state: model.providerConfig.modelName.isEmpty ? .actionNeeded : .ready
            ),
            ReadinessItem(
                id: "mic",
                title: "Microphone permission",
                detail: model.microphonePermissionDetail,
                state: model.microphonePermissionState
            ),
            ReadinessItem(
                id: "speech",
                title: "Speech permission",
                detail: model.speechPermissionDetail,
                state: model.speechPermissionState
            ),
            ReadinessItem(
                id: "accessibility",
                title: "Accessibility permission",
                detail: model.computerControlStatus.hasPrefix("Ready") ? "Mac control ready" : "Needed for typing and clicks",
                state: model.computerControlStatus.hasPrefix("Ready") ? .ready : .warning
            ),
            ReadinessItem(
                id: "voice",
                title: "Voice ready",
                detail: model.voiceConfig.providerID == "macos" ? "macOS voice" : model.voiceConfig.providerName,
                state: model.voiceConfig.providerID == "macos" || model.voiceAPIKeyStatus.contains("saved") ? .ready : .warning
            )
        ]
    }
}

private struct ChecklistRow: View {
    let item: ReadinessItem

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                Text(item.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    private var icon: String {
        switch item.state {
        case .ready: "checkmark.circle.fill"
        case .warning: "exclamationmark.circle.fill"
        case .actionNeeded: "circle"
        }
    }

    private var color: Color {
        switch item.state {
        case .ready: .green
        case .warning: .orange
        case .actionNeeded: .secondary
        }
    }
}

private struct InspectorConfirmationCard: View {
    @EnvironmentObject private var model: AppModel
    let task: AgentTask

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("Confirmation needed", systemImage: "hand.raised.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Text(task.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)

                HStack {
                    Button("Cancel") {
                        model.cancelPendingTask()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Confirm") {
                        model.confirmPendingTask()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.orange.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct InspectorPlanCard: View {
    let task: AgentTask

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Task")
                            .font(.headline)
                        Text(task.expectedResult)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    Spacer()

                    RiskPill(level: task.riskLevel)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Plan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(Array(task.steps.prefix(4).enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 17, height: 17)
                                .background(Color.accentColor)
                                .clipShape(Circle())

                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                        }
                    }
                }

                if task.requiresConfirmation {
                    Label("Will ask before the final action", systemImage: "lock.shield.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

private struct InspectorTimeline: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Action timeline")
                    .font(.headline)

                if model.taskRunSteps.isEmpty {
                    Text("No active task yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.taskRunSteps.prefix(5)) { step in
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: icon(for: step.state))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(color(for: step.state))
                                .frame(width: 15)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(2)
                                Text(step.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
    }

    private func icon(for state: TaskRunStep.State) -> String {
        switch state {
        case .pending: "circle"
        case .running: "arrow.triangle.2.circlepath"
        case .completed: "checkmark.circle.fill"
        case .blocked: "hand.raised.fill"
        case .failed: "xmark.circle.fill"
        }
    }

    private func color(for state: TaskRunStep.State) -> Color {
        switch state {
        case .pending: .secondary
        case .running: .blue
        case .completed: .green
        case .blocked: .orange
        case .failed: .red
        }
    }
}

private struct SuggestedActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.74))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct QuietPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.035), radius: 8, y: 3)
    }
}

private struct ChatView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selectedTab: PanelTab
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        if model.shouldShowOnboarding {
                            OnboardingCard(selectedTab: $selectedTab)
                        }

                        if model.setupNeedsAttention {
                            SetupCard(selectedTab: $selectedTab)
                        }

                        SkillStripView()

                        TaskRunTimeline()

                        BrowserResultsPanel()

                        LazyVStack(spacing: 12) {
                            ForEach(model.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(16)
                }
                .onChange(of: model.messages.count) { _ in
                    if let last = model.messages.last {
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if let pending = model.pendingConfirmation {
                ConfirmationBar(task: pending)
            }

            inputBar
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentColor.opacity(0.08))
                    )
                    .padding(10)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            handleFileDrop(providers)
        }
    }

    private var inputBar: some View {
        VStack(spacing: 10) {
            if !model.pendingAttachments.isEmpty {
                PendingAttachmentTray()
            }

            HStack(spacing: 10) {
                Button {
                    model.chooseAttachments()
                } label: {
                    Image(systemName: "paperclip")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Circle())
                .help("Attach photos, videos, or files")

                Button {
                    model.captureScreenAttachment()
                } label: {
                    Image(systemName: "camera.viewfinder")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Circle())
                .help("Capture the current screen")

                TextField("Ask Earth Agent...", text: $model.typedMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .tint(.blue)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onSubmit {
                        model.sendTypedMessage()
                    }

                Button {
                    if model.isListening {
                        model.stopListeningAndSend()
                    } else {
                        model.startListening()
                    }
                } label: {
                    Image(systemName: model.isListening ? "paperplane.fill" : "mic.fill")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(model.isListening ? Color.green : Color.accentColor)
                .clipShape(Circle())
                .keyboardShortcut(" ", modifiers: [.command])
                .help(model.isListening ? "Send voice" : "Dictate")

                Button {
                    model.sendTypedMessage()
                } label: {
                    Image(systemName: "arrow.up")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Color.accentColor)
                .clipShape(Circle())
                .help("Send")
            }

            HStack(spacing: 8) {
                Label(model.safetyMode.rawValue, systemImage: "shield.lefthalf.filled")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label(model.voiceTurnState.shortLabel, systemImage: voiceStateIcon)
                    .font(.caption2)
                    .foregroundStyle(model.isConversationMode ? Color.accentColor : .secondary)
                    .lineLimit(1)

                Label("Drop files or capture screen", systemImage: "photo.on.rectangle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Button {
                    model.toggleConversationMode()
                } label: {
                    Label(model.isConversationMode ? "Stop Talk" : "Live Talk", systemImage: model.isConversationMode ? "stop.fill" : "waveform")
                }
                .font(.caption)
                .buttonStyle(.borderless)

                Button {
                    model.pauseTask()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
    }

    private var voiceStateIcon: String {
        switch model.voiceTurnState {
        case .idle: "speaker.wave.1"
        case .listening: "mic.fill"
        case .processing: "brain.head.profile"
        case .speaking: "speaker.wave.2.fill"
        case .interrupted: "hand.raised.fill"
        case .paused: "pause.circle.fill"
        case .stopped: "stop.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
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

private struct PendingAttachmentTray: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.pendingAttachments) { attachment in
                    AttachmentChip(attachment: attachment, canRemove: true) {
                        model.removePendingAttachment(attachment)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct OnboardingCard: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selectedTab: PanelTab

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checklist.checked")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Earth Agent")
                        .font(.headline)
                    Text("Earth Agent helps you control your Mac with AI, voice, and safe confirmations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                OnboardingChip(title: "AI", isReady: model.hasSavedAPIKey && !model.providerConfig.modelName.isEmpty)
                OnboardingChip(title: "Model", isReady: !model.providerConfig.modelName.isEmpty)
                OnboardingChip(title: "Voice", isReady: model.voiceConfig.providerID == "macos" || model.voiceAPIKeyStatus.contains("saved"))
                OnboardingChip(title: "Mic", isReady: model.voiceTurnState != .failed)
                OnboardingChip(title: "Control", isReady: model.computerControlStatus.hasPrefix("Ready"))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Try now")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 8)], spacing: 8) {
                    ExampleCommandButton(title: "Summarize file", prompt: "Summarize the file I upload and give me the key points.")
                    ExampleCommandButton(title: "Draft message", prompt: "Draft a clear message. Do not send it.")
                    ExampleCommandButton(title: "Web research", prompt: "Search the web for AI automation tools.")
                    ExampleCommandButton(title: "Computer status", prompt: "Advanced computer use status.")
                }
            }

            HStack {
                Button("Settings") {
                    selectedTab = .settings
                }
                Button("Tasks") {
                    selectedTab = .tasks
                }
                Button("Safety") {
                    selectedTab = .safety
                }
                Spacer()
                Button("Done") {
                    model.completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(Color.green.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.green.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct ExampleCommandButton: View {
    @EnvironmentObject private var model: AppModel
    let title: String
    let prompt: String

    var body: some View {
        Button {
            model.submitUserText(prompt)
        } label: {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.76))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct OnboardingChip: View {
    let title: String
    let isReady: Bool

    var body: some View {
        Label(title, systemImage: isReady ? "checkmark.circle.fill" : "circle")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isReady ? .green : .secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SetupCard: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selectedTab: PanelTab

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Finish setup")
                        .font(.headline)
                    Text("Connect a provider, choose a model, then test it once. Earth will feel much less mysterious after that.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Open Settings") {
                    selectedTab = .settings
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 8) {
                ForEach(model.readinessItems.prefix(3)) { item in
                    ReadinessChip(item: item)
                }
            }
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.accentColor.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct ReadinessStrip: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.readinessItems) { item in
                    ReadinessChip(item: item)
                        .frame(width: 132)
                }
            }
        }
    }
}

private struct ReadinessChip: View {
    let item: ReadinessItem

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.caption2.weight(.semibold))
                Text(item.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var color: Color {
        switch item.state {
        case .ready: .green
        case .warning: .yellow
        case .actionNeeded: .red
        }
    }
}

private struct SkillStripView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Quick skills")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(model.skillCards) { skill in
                        Button {
                            model.runSkill(skill)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: skill.systemImage)
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(Color.accentColor)
                                    .background(Color.accentColor.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(skill.title)
                                        .font(.caption.weight(.semibold))
                                    Text(skill.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(10)
                            .frame(width: 124, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .help(skill.prompt)
                    }
                }
            }
        }
    }
}

private struct TaskRunTimeline: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if !model.taskRunSteps.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .foregroundStyle(Color.accentColor)
                    Text(model.activeTaskTitle ?? "Task progress")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(model.status.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 7) {
                    ForEach(model.taskRunSteps) { step in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: icon(for: step.state))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(color(for: step.state))
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(.caption)
                                    .lineLimit(2)
                                Text(step.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func icon(for state: TaskRunStep.State) -> String {
        switch state {
        case .pending: "circle"
        case .running: "circle.dotted"
        case .completed: "checkmark.circle.fill"
        case .blocked: "pause.circle.fill"
        case .failed: "xmark.circle.fill"
        }
    }

    private func color(for state: TaskRunStep.State) -> Color {
        switch state {
        case .pending: .secondary
        case .running: .blue
        case .completed: .green
        case .blocked: .orange
        case .failed: .red
        }
    }
}

private struct BrowserResultsPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if !model.browserCandidates.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Browser results", systemImage: "list.bullet.rectangle")
                        .font(.caption.weight(.semibold))
                    Spacer()
                }

                ForEach(model.browserCandidates.prefix(5)) { candidate in
                    HStack(alignment: .top, spacing: 8) {
                        Text("#\(candidate.id)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 26, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(candidate.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text("\(candidate.kind.rawValue) • element #\(candidate.elementID)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                }

            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

private struct ConfirmationBar: View {
    @EnvironmentObject private var model: AppModel
    let task: AgentTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Confirm action")
                    .font(.subheadline.weight(.semibold))
                Text(task.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button("Cancel") {
                model.cancelPendingTask()
            }

            Button("Confirm") {
                model.confirmPendingTask()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(Color.orange.opacity(0.10))
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 70)
            } else {
                EarthMiniIcon(size: 26)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(message.content)
                    .font(.system(size: 14))
                    .lineSpacing(2)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                if !message.attachments.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 6)], alignment: .leading, spacing: 6) {
                        ForEach(message.attachments) { attachment in
                            AttachmentChip(attachment: attachment, canRemove: false, onRemove: {})
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if message.role != .user {
                Spacer(minLength: 70)
            }
        }
    }

    private var label: String {
        switch message.role {
        case .user: "You"
        case .assistant: "Earth"
        case .system: "System"
        }
    }

    private var background: Color {
        switch message.role {
        case .user:
            Color.accentColor.opacity(0.16)
        case .assistant:
            Color(nsColor: .controlBackgroundColor)
        case .system:
            Color.gray.opacity(0.12)
        }
    }
}

private struct AttachmentChip: View {
    let attachment: ChatAttachment
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text("\(attachment.kind.rawValue) • \(attachment.displaySize)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if attachment.kind == .photo && attachment.byteCount <= 4_000_000 {
                    Text("Vision-ready")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                        .lineLimit(1)
                }
            }

            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .background(Color.black.opacity(0.06))
                .clipShape(Circle())
                .help("Remove attachment")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

private struct TasksView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Tasks",
                    subtitle: "Earth explains intent, risk, tools, progress, and what happens if something fails."
                )

                if let task = model.latestPlan {
                    PlanSummaryCard(task: task)
                } else {
                    EmptyStateCard(
                        systemImage: "checklist",
                        title: "No active plan yet",
                        detail: "Ask Earth to summarize a file, research the web, draft a message, inspect a browser, create a website, or control a focused app."
                    )
                }

                TaskRunTimeline()

                PromptQueueCard()

                AgentToolRegistryCard()

                TaskHistoryCard()

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Public Assistant Workflows", systemImage: "sparkles")
                                .font(.headline)
                            Spacer()
                            Button {
                                model.submitUserText("Search the web for AI automation tools.")
                            } label: {
                                Label("Research", systemImage: "magnifyingglass")
                            }
                            .buttonStyle(.borderedProminent)
                            Button {
                                model.submitUserText("Look at my screen and help me understand what to do next.")
                            } label: {
                                Label("Screen Help", systemImage: "rectangle.and.text.magnifyingglass")
                            }
                        }

                        Text("Earth can answer, research, inspect visible UI, summarize files, draft text, and keep external actions under your control.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            QuickTaskButton(title: "Summarize", prompt: "Summarize my clipboard.")
                            QuickTaskButton(title: "Inspect", prompt: "Inspect visible UI elements.")
                            QuickTaskButton(title: "Agents", prompt: "Use all 30 agents to review this plan.")
                            QuickTaskButton(title: "Readiness", prompt: "Show launch readiness report.")
                        }
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Website Builder", systemImage: "globe")
                                .font(.headline)
                            Spacer()
                            Button {
                                model.submitUserText("Create a simple local website for my idea.")
                            } label: {
                                Label("Create", systemImage: "sparkles")
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Text("Earth can create local editable website files and open a browser preview. This stays on your Mac unless you choose to publish it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            QuickTaskButton(title: "Simple", prompt: "Create a simple local website for my idea.")
                            QuickTaskButton(title: "Modern", prompt: "Create a modern local website for my product idea.")
                            QuickTaskButton(title: "Dark", prompt: "Create a dark local website for my project.")
                            QuickTaskButton(title: "Startup", prompt: "Create a startup-style local website for my product.")
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

private struct TaskHistoryCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(
                        title: "Background Task History",
                        subtitle: "Recent work Earth planned, ran, paused, completed, or failed."
                    )

                    Spacer()

                    if !model.taskHistory.isEmpty {
                        Button("Clear") {
                            model.clearTaskHistory()
                        }
                        .buttonStyle(.borderless)
                    }
                }

                if model.taskHistory.isEmpty {
                    EmptyStateCard(
                        systemImage: "clock.badge.checkmark",
                        title: "No task history yet",
                        detail: "Ask Earth to run a task. It will appear here and stay available after relaunch."
                    )
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(model.taskHistory.prefix(12)) { entry in
                            TaskHistoryRow(entry: entry)
                        }
                    }
                }
            }
        }
    }
}

private struct PromptQueueCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(
                        title: "Prompt Queue",
                        subtitle: "New commands wait here while Earth is thinking or working."
                    )
                    Spacer()
                    if !model.queuedPrompts.isEmpty {
                        Text("\(model.queuedPrompts.count) queued")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                if model.queuedPrompts.isEmpty {
                    EmptyStateCard(
                        systemImage: "text.line.first.and.arrowtriangle.forward",
                        title: "Nothing queued",
                        detail: "If you type while Earth is working, your next command will appear here instead of being lost."
                    )
                } else {
                    ForEach(model.queuedPrompts) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.orange)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.text)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(2)
                                Text(entry.queuedAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                model.promoteQueuedPrompt(entry)
                            } label: {
                                Image(systemName: "arrow.up")
                            }
                            .buttonStyle(.borderless)
                            Button(role: .destructive) {
                                model.removeQueuedPrompt(entry)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(10)
                        .background(Color(nsColor: .windowBackgroundColor).opacity(0.62))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
    }
}

private struct AgentToolRegistryCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(
                        title: "Tool Registry",
                        subtitle: "Every action declares risk, permission, status, and confirmation rules."
                    )
                    Spacer()
                    Button {
                        model.refreshAgentTools()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                    ForEach(model.agentTools) { tool in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(tool.isEnabled ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(tool.title)
                                    .font(.caption.weight(.semibold))
                                Spacer()
                                RiskPill(level: tool.risk)
                            }
                            Text(tool.summary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            HStack(spacing: 6) {
                                HistoryPill(text: tool.toolset, color: .blue)
                                HistoryPill(text: tool.permission.rawValue, color: .secondary)
                            }
                            Text("\(tool.status) • \(tool.confirmationPolicy.rawValue)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(tool.isEnabled ? .green : .orange)
                        }
                        .padding(10)
                        .background(Color(nsColor: .windowBackgroundColor).opacity(0.62))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
    }
}

private struct TaskHistoryRow: View {
    let entry: TaskHistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                    Text(entry.summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer()

                Text(timeText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                HistoryPill(text: entry.state.rawValue, color: color)
                HistoryPill(text: entry.risk, color: riskColor)
                HistoryPill(text: entry.category, color: .secondary)
                if entry.requiresConfirmation {
                    HistoryPill(text: "Confirmed", color: .orange)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var timeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: entry.updatedAt, relativeTo: Date())
    }

    private var icon: String {
        switch entry.state {
        case .planned: "checklist"
        case .waitingForConfirmation: "hand.raised.fill"
        case .running: "arrow.triangle.2.circlepath"
        case .completed: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        case .paused: "pause.circle.fill"
        case .cancelled: "stop.circle.fill"
        }
    }

    private var color: Color {
        switch entry.state {
        case .planned: .blue
        case .waitingForConfirmation: .orange
        case .running: .blue
        case .completed: .green
        case .failed: .red
        case .paused: .yellow
        case .cancelled: .secondary
        }
    }

    private var riskColor: Color {
        switch entry.risk {
        case "High": .red
        case "Medium": .orange
        default: .green
        }
    }
}

private struct HistoryPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct PlanSummaryCard: View {
    let task: AgentTask

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.category.rawValue)
                            .font(.headline)
                        Text(task.explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    RiskPill(level: task.riskLevel)
                }

                HStack(spacing: 8) {
                    DetailChip(title: "Confirmation", value: task.requiresConfirmation ? "Required" : "Not needed", systemImage: task.requiresConfirmation ? "hand.raised.fill" : "checkmark.circle.fill")
                    DetailChip(title: "Tools", value: task.requiredTools.joined(separator: ", "), systemImage: "wrench.and.screwdriver")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Steps")
                        .font(.caption.weight(.semibold))
                    ForEach(Array(task.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 18, height: 18)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                                .clipShape(Circle())
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                Text("Expected result: \(task.expectedResult)")
                    .font(.caption)
                Text("Fallback: \(task.fallback)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct RiskPill: View {
    let level: AgentTask.RiskLevel

    var body: some View {
        Text(level.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch level {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}

private struct DetailChip: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                Text(value)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct QuickTaskButton: View {
    @EnvironmentObject private var model: AppModel
    let title: String
    let prompt: String

    var body: some View {
        Button(title) {
            model.submitUserText(prompt)
        }
        .font(.caption)
        .buttonStyle(.bordered)
    }
}

private struct MemoryView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Memory",
                    subtitle: "Memory is opt-in. Earth only remembers what you explicitly save."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Never save passwords, API keys, private financial data, or secrets here.")
                            .font(.caption)
                            .foregroundStyle(.orange)

                        HStack {
                            TextField("Example: I prefer short, direct answers", text: $model.memoryDraft)
                                .textFieldStyle(.roundedBorder)
                            Picker("", selection: $model.memoryCategoryDraft) {
                                ForEach(UserMemoryEntry.Category.allCases) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 150)
                            Button("Remember") {
                                model.rememberDraft()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.memoryDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "Session Search",
                            subtitle: "Search previous Earth messages and continue from an old thread."
                        )

                        HStack {
                            TextField("Search previous chats", text: $model.sessionSearchQuery)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    model.searchSessions()
                                }
                            Button {
                                model.searchSessions()
                            } label: {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                        }

                        if model.sessionSearchResults.isEmpty {
                            EmptyStateCard(
                                systemImage: "clock.arrow.circlepath",
                                title: model.sessionSearchQuery.isEmpty ? "Search your history" : "No matches",
                                detail: "Earth archives local chat text so you can find past decisions without saving everything as memory."
                            )
                        } else {
                            ForEach(model.sessionSearchResults) { result in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: result.entry.role == .user ? "person.fill" : "globe.americas.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(result.entry.role == .user ? "You" : "Earth")
                                            .font(.caption.weight(.semibold))
                                        Text(result.snippet)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(3)
                                        Text(result.entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        model.continueFromSearchResult(result)
                                    } label: {
                                        Image(systemName: "arrowshape.turn.up.forward.fill")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Continue from this result")
                                }
                                .padding(10)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.62))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                }

                if model.memories.isEmpty {
                    EmptyStateCard(
                        systemImage: "brain.head.profile",
                        title: "No memories saved",
                        detail: "Say 'Remember that I prefer concise answers' or save a memory manually above."
                    )
                } else {
                    ForEach(UserMemoryEntry.Category.allCases) { category in
                        let entries = model.memories.filter { $0.category == category }
                        if !entries.isEmpty {
                            SettingsCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(category.rawValue)
                                        .font(.headline)
                                    ForEach(entries) { memory in
                                        MemoryEditorRow(memory: memory)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

private struct MemoryEditorRow: View {
    @EnvironmentObject private var model: AppModel
    let memory: UserMemoryEntry
    @State private var draft = ""
    @State private var category: UserMemoryEntry.Category = .preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(memory.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(role: .destructive) {
                    model.deleteMemory(memory)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            TextField("Memory", text: $draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)

            HStack {
                Picker("", selection: $category) {
                    ForEach(UserMemoryEntry.Category.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .labelsHidden()
                Spacer()
                Button("Save") {
                    model.updateMemory(memory, text: draft, category: category)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear {
            draft = memory.text
            category = memory.category
        }
    }
}

private struct LogsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Logs",
                    subtitle: "Local transparency log for commands, plans, actions, confirmations, results, and errors."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(model.logs.count) local entries")
                                .font(.headline)
                            Spacer()
                            Button(role: .destructive) {
                                model.deleteLogsOnly()
                            } label: {
                                Label("Clear Logs", systemImage: "trash")
                            }
                        }

                        if let task = model.latestPlan {
                            PlanAuditView(task: task)
                        } else {
                            Text("No interpreted plan yet.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if model.logs.isEmpty {
                    EmptyStateCard(systemImage: "list.clipboard", title: "No logs yet", detail: "Use Earth once and this tab will show the local action trail.")
                } else {
                    SettingsCard {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(model.logs.prefix(160)) { entry in
                                HStack(alignment: .top, spacing: 10) {
                                    Text(entry.createdAt.formatted(date: .omitted, time: .standard))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 82, alignment: .leading)
                                    Text(entry.message)
                                        .font(.caption)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                Divider().opacity(0.45)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

private struct PlanAuditView: View {
    let task: AgentTask

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HealthRow(title: "Command", detail: task.userText, state: .ready)
            HealthRow(title: "Interpretation", detail: task.category.rawValue, state: .ready)
            HealthRow(title: "Planned action", detail: task.explanation, state: .ready)
            HealthRow(title: "Tools", detail: task.requiredTools.joined(separator: ", "), state: .ready)
            HealthRow(title: "Confirmation", detail: task.requiresConfirmation ? "Required" : "Not required", state: task.requiresConfirmation ? .warning : .ready)
            HealthRow(title: "Risk", detail: "\(task.riskLevel.rawValue): \(task.riskLevel.shortDescription)", state: task.riskLevel == .high ? .warning : .ready)
            HealthRow(title: "Fallback", detail: task.fallback, state: .warning)
        }
    }
}

private struct EmptyStateCard: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct AgentsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Routines",
                    subtitle: "Local scheduled tasks. Earth asks before a routine runs."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(model.routineStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                model.submitUserText("List routines.")
                            } label: {
                                Label("Show", systemImage: "list.bullet")
                            }
                        }

                        ForEach(Array(model.routines.enumerated()), id: \.element.id) { index, routine in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22, height: 22)
                                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(routine.title)
                                        .font(.caption.weight(.semibold))
                                    Text(routine.prompt)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    Text("\(routine.schedule.rawValue) • \(routine.statusText)")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(routine.isEnabled ? .green : .secondary)
                                    Text("\(routine.pinnedProviderName) • \(routine.pinnedModelName) • \(routine.toolset)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button {
                                    model.runRoutine(routine)
                                } label: {
                                    Image(systemName: "play.fill")
                                }
                                .buttonStyle(.borderless)
                                .help("Run routine")

                                Button {
                                    model.toggleRoutine(routine)
                                } label: {
                                    Image(systemName: routine.isEnabled ? "bell.fill" : "bell")
                                }
                                .buttonStyle(.borderless)
                                .help(routine.isEnabled ? "Turn off routine" : "Enable routine")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                SectionHeader(
                    title: "Skills",
                    subtitle: "Reusable Earth abilities inspired by Hermes-style SKILL packages."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        LazyVGrid(columns: agentColumns, alignment: .leading, spacing: 10) {
                            ForEach(model.earthSkills) { skill in
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack {
                                        Text(skill.name)
                                            .font(.caption.weight(.semibold))
                                        Spacer()
                                        Text(skill.category.rawValue)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                    Text(skill.summary)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    Text("Tools: \(skill.requiredTools.joined(separator: ", "))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }

                        if !model.skillMatches.isEmpty {
                            Divider()
                            Text("Matched for latest request")
                                .font(.caption.weight(.semibold))
                            HStack {
                                ForEach(model.skillMatches.prefix(4)) { match in
                                    HistoryPill(text: match.skill.name, color: .green)
                                }
                            }
                        }
                    }
                }

                SectionHeader(
                    title: "Agent Swarm",
                    subtitle: "30 internal specialists split bigger requests, work in parallel, and merge into one safe plan."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("\(model.subagentProfiles.count) agents available", systemImage: "person.3.sequence.fill")
                                .font(.caption.weight(.semibold))
                            Spacer()
                            Text("Focused squad by default. Full swarm on request.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: agentColumns, alignment: .leading, spacing: 10) {
                            ForEach(model.subagentProfiles) { profile in
                                VStack(alignment: .leading, spacing: 5) {
                                    Image(systemName: profile.id.systemImage)
                                        .foregroundStyle(Color.accentColor)
                                    Text(profile.title)
                                        .font(.caption.weight(.semibold))
                                    Text(profile.purpose)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }

                        HStack {
                            Button {
                                let prompt = model.typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                                model.submitUserText("Use agent swarm to review: \(prompt.isEmpty ? "make Earth Agent smoother and more useful" : prompt)")
                            } label: {
                                Label("Run Swarm", systemImage: "person.3.sequence.fill")
                            }
                            .buttonStyle(.borderedProminent)

                            Text("Uses your selected AI provider.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if !model.subagentRuns.isEmpty {
                            Divider()
                            ForEach(model.subagentRuns) { run in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: run.role.systemImage)
                                        .foregroundStyle(color(for: run.state))
                                        .frame(width: 18)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(run.title) • \(run.state.rawValue)")
                                            .font(.caption.weight(.semibold))
                                        Text(run.summary)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(3)
                                    }
                                }
                            }
                        }
                    }
                }

                SectionHeader(
                    title: "MCP Connectors",
                    subtitle: "Connector settings are local. External tools still need explicit permission."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(model.mcpStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(model.mcpConnectors) { connector in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: connectorIcon(for: connector))
                                    .foregroundStyle(riskColor(connector.risk))
                                    .frame(width: 22)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(connector.name)
                                        .font(.caption.weight(.semibold))
                                    Text("\(connector.subtitle) • \(connector.transport.rawValue) • risk \(connector.risk.rawValue)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(connector.notes)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    if let enabledTools = connector.enabledTools, !enabledTools.isEmpty {
                                        Text("Enabled tools: \(enabledTools.joined(separator: ", "))")
                                            .font(.caption2)
                                            .foregroundStyle(Color.accentColor)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Text(connector.status.rawValue)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(connector.isEnabled ? .green : .secondary)

                                Button {
                                    model.checkMCPConnector(connector)
                                } label: {
                                    Image(systemName: "checkmark.seal")
                                }
                                .buttonStyle(.borderless)

                                Button {
                                    model.toggleMCPConnector(connector)
                                } label: {
                                    Image(systemName: connector.isEnabled ? "power.circle.fill" : "power.circle")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }

                SectionHeader(
                    title: "Social Connectors",
                    subtitle: "Remote approvals and notifications for Telegram, WhatsApp, Slack, Discord, and Email."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(model.socialStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(model.socialConnectors) { connector in
                            SocialConnectorRow(connector: connector)
                        }

                        Text("Earth will not send, post, or message externally without explicit confirmation. These connectors are for approvals, notifications, and future remote command surfaces.")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                SectionHeader(
                    title: "Advanced Computer Use",
                    subtitle: "Native macOS control with confirmation, pause, and hard safety blocks."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button {
                                model.submitUserText("Advanced computer use status.")
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }

                            Button {
                                model.submitUserText("List running apps.")
                            } label: {
                                Label("Apps", systemImage: "macwindow.on.rectangle")
                            }

                            Spacer()
                        }

                        if let report = model.computerUseReport {
                            HealthRow(
                                title: "Active app",
                                detail: report.activeApp,
                                state: .ready
                            )
                            HealthRow(
                                title: "Permission",
                                detail: report.accessibilityTrusted ? "Accessibility enabled" : "Accessibility needed",
                                state: report.accessibilityTrusted ? .ready : .warning
                            )

                            ForEach(report.capabilities) { capability in
                                HStack(spacing: 9) {
                                    Image(systemName: capability.systemImage)
                                        .foregroundStyle(color(for: capability.state))
                                        .frame(width: 18)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(capability.title)
                                            .font(.caption.weight(.semibold))
                                        Text(capability.detail)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }

                            if !report.visibleWindows.isEmpty {
                                Divider()
                                Text("Visible windows")
                                    .font(.caption.weight(.semibold))
                                ForEach(report.visibleWindows.prefix(5), id: \.self) { window in
                                    Text(window)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private func color(for state: SubagentRun.State) -> Color {
        switch state {
        case .pending: .secondary
        case .running: .blue
        case .completed: .green
        case .failed: .red
        }
    }

    private func connectorIcon(for connector: MCPConnectorProfile) -> String {
        switch connector.risk {
        case .low: "link.circle"
        case .medium: "point.3.connected.trianglepath.dotted"
        case .high: "exclamationmark.shield"
        }
    }

    private var agentColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 132, maximum: 190), spacing: 10, alignment: .top)
        ]
    }

    private func riskColor(_ risk: MCPConnectorProfile.Risk) -> Color {
        switch risk {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }

    private func color(for state: ComputerUseCapability.State) -> Color {
        switch state {
        case .ready: .green
        case .needsPermission: .orange
        case .confirmationRequired: .blue
        case .planned: .secondary
        }
    }
}

private struct SocialConnectorRow: View {
    @EnvironmentObject private var model: AppModel
    let connector: SocialConnectorProfile
    @State private var webhookURL = ""
    @State private var destination = ""
    @State private var token = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(connector.isEnabled ? Color.green : Color.accentColor)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(connector.displayName)
                        .font(.caption.weight(.semibold))
                    Text("\(connector.status.rawValue) • \(connector.botTokenSaved ? "secret saved" : "no secret saved")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(connector.notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    model.toggleSocialConnector(connector)
                } label: {
                    Image(systemName: connector.isEnabled ? "power.circle.fill" : "power.circle")
                }
                .buttonStyle(.borderless)
            }

            HStack {
                TextField("Webhook URL or callback URL", text: $webhookURL)
                    .textFieldStyle(.roundedBorder)
                TextField("Allowed chat, channel, phone, or email", text: $destination)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                SecureField("Bot token or API secret", text: $token)
                    .textFieldStyle(.roundedBorder)
                Button {
                    model.updateSocialConnector(connector, webhookURL: webhookURL, destination: destination, token: token)
                    token = ""
                } label: {
                    Label("Save", systemImage: "lock.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear {
            webhookURL = connector.webhookURL
            destination = connector.allowedDestination
        }
    }

    private var icon: String {
        switch connector.platform {
        case .telegram: "paperplane.fill"
        case .whatsapp: "phone.bubble.left.fill"
        case .slack: "number"
        case .discord: "bubble.left.and.bubble.right.fill"
        case .email: "envelope.fill"
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedProviderID = "openai"
    @State private var selectedModel = ""
    @State private var customProviderName = ""
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var selectedVoiceProviderID = "macos"
    @State private var selectedVoiceModel = "system"
    @State private var selectedVoiceID = "system-default"
    @State private var voiceBaseURL = ""
    @State private var voiceAPIKey = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LaunchReadinessDetailCard()

                SectionHeader(
                    title: "App behavior",
                    subtitle: "Keep Earth available as a background assistant."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { model.launchAtLoginEnabled },
                            set: { model.setLaunchAtLogin($0) }
                        )) {
                            Label("Start Earth Agent at login", systemImage: "power.circle.fill")
                                .font(.headline)
                        }

                        HealthRow(
                            title: "Startup",
                            detail: model.launchAtLoginStatus,
                            state: model.launchAtLoginEnabled ? .ready : .warning
                        )

                        HealthRow(
                            title: "Shortcuts",
                            detail: model.shortcutStatus,
                            state: .ready
                        )
                    }
                }

                SectionHeader(
                    title: "AI connection",
                    subtitle: "Choose a provider, save your key, test once, then pick the model."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Provider", selection: $selectedProviderID) {
                            ForEach(model.providers) { provider in
                                Text(provider.name).tag(provider.id)
                            }
                        }
                        .onChange(of: selectedProviderID) { providerID in
                            let provider = ProviderCatalog.provider(id: providerID)
                            model.applyProviderSelection(provider)
                            customProviderName = provider.name
                            baseURL = provider.baseURL
                            selectedModel = provider.defaultModel
                        }

                        if selectedProviderID == ProviderProfile.custom.id {
                            TextField("Provider name", text: $customProviderName)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("Base URL") {
                            TextField("https://api.example.com/v1", text: $baseURL)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("Model") {
                            Picker("", selection: $selectedModel) {
                                ForEach(model.availableModels, id: \.self) { modelName in
                                    Text(modelName).tag(modelName)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: selectedModel) { modelName in
                                model.setSelectedModel(modelName)
                            }
                        }

                        SecureField("API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)

                        HStack(spacing: 8) {
                            Button {
                                saveSettings()
                            } label: {
                                Label("Save", systemImage: "lock.fill")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                model.providerConfig.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                model.testProviderConnection(apiKeyFromField: apiKey)
                            } label: {
                                Label(model.isTestingProvider ? "Testing" : "Test", systemImage: "bolt.horizontal.circle")
                            }
                            .disabled(model.isTestingProvider)

                            Button {
                                model.providerConfig.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                model.refreshModels(apiKeyFromField: apiKey)
                            } label: {
                                Label(model.isRefreshingModels ? "Refreshing" : "Models", systemImage: "arrow.clockwise")
                            }
                            .disabled(model.isRefreshingModels)
                        }
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HealthRow(title: "Keychain", detail: model.apiKeyStatus, state: model.hasSavedAPIKey ? .ready : .actionNeeded)
                        HealthRow(title: "Connection", detail: model.providerTestStatus, state: model.isProviderConnected ? .ready : .warning)
                        HealthRow(title: "Models", detail: model.modelRefreshStatus, state: model.availableModels.isEmpty ? .warning : .ready)
                    }
                }

                SectionHeader(
                    title: "Voice connection",
                    subtitle: "Use macOS voice for free, or connect ElevenLabs/OpenAI for a more natural assistant voice."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Voice provider", selection: $selectedVoiceProviderID) {
                            ForEach(model.voiceProviders) { provider in
                                Text(provider.name).tag(provider.id)
                            }
                        }
                        .onChange(of: selectedVoiceProviderID) { providerID in
                            let provider = VoiceProviderCatalog.provider(id: providerID)
                            model.applyVoiceProviderSelection(provider)
                            selectedVoiceModel = provider.defaultModel
                            selectedVoiceID = provider.defaultVoice
                            voiceBaseURL = provider.baseURL
                        }

                        LabeledContent("Base URL") {
                            TextField("https://api.voice-provider.com/v1", text: $voiceBaseURL)
                                .textFieldStyle(.roundedBorder)
                                .disabled(selectedVoiceProviderID == "macos")
                        }

                        LabeledContent("Voice model") {
                            Picker("", selection: $selectedVoiceModel) {
                                ForEach(model.availableVoiceModels, id: \.self) { modelName in
                                    Text(modelName).tag(modelName)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: selectedVoiceModel) { modelName in
                                model.setSelectedVoiceModel(modelName)
                            }
                        }

                        LabeledContent("Voice ID") {
                            Picker("", selection: $selectedVoiceID) {
                                ForEach(model.availableVoiceIDs, id: \.self) { voiceID in
                                    Text(model.displayNameForVoiceID(voiceID)).tag(voiceID)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: selectedVoiceID) { voiceID in
                                model.setSelectedVoiceID(voiceID)
                            }
                        }

                        TextField(selectedVoiceProviderID == "macos" ? "Selected macOS voice ID" : "Paste custom voice ID here if needed", text: $selectedVoiceID)
                            .textFieldStyle(.roundedBorder)
                            .disabled(selectedVoiceProviderID == "macos")

                        SecureField("Voice API key", text: $voiceAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .disabled(selectedVoiceProviderID == "macos")

                        HStack(spacing: 8) {
                            Button {
                                saveVoiceSettings()
                            } label: {
                                Label("Save Voice", systemImage: "lock.fill")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                saveVoiceSettings()
                                model.testVoice(apiKeyFromField: voiceAPIKey)
                            } label: {
                                Label("Test Voice", systemImage: "speaker.wave.2.fill")
                            }
                            .disabled(VoiceProviderCatalog.provider(id: selectedVoiceProviderID).status == .planned)
                        }
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HealthRow(title: "Voice key", detail: model.voiceAPIKeyStatus, state: selectedVoiceProviderID == "macos" || model.voiceAPIKeyStatus.contains("saved") ? .ready : .warning)
                        HealthRow(title: "Voice test", detail: model.voiceTestStatus, state: model.voiceTestStatus.contains("played") || selectedVoiceProviderID == "macos" ? .ready : .warning)
                        Text(VoiceProviderCatalog.provider(id: selectedVoiceProviderID).notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Voice diagnostics", systemImage: "stethoscope")
                                .font(.headline)
                            Spacer()
                            Button {
                                model.refreshPrivacyPermissionStatus()
                                model.refreshVoiceDiagnostics()
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        }

                        ForEach(model.voiceDiagnostics) { item in
                            HealthRow(title: item.layer.rawValue, detail: item.detail, state: item.state)
                        }
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Live Talk timing", systemImage: "waveform.and.mic")
                            .font(.headline)

                        LabeledContent("Silence delay") {
                            Stepper(
                                "\(model.voiceTurnSettings.silenceDelay, specifier: "%.1f") sec",
                                value: $model.voiceTurnSettings.silenceDelay,
                                in: 0.6...2.6,
                                step: 0.1
                            )
                        }

                        LabeledContent("Minimum speech") {
                            Stepper(
                                "\(model.voiceTurnSettings.minimumWordCount) words",
                                value: $model.voiceTurnSettings.minimumWordCount,
                                in: 1...5
                            )
                        }

                        LabeledContent("Listening timeout") {
                            Stepper(
                                "\(Int(model.voiceTurnSettings.maximumListeningDuration)) sec",
                                value: $model.voiceTurnSettings.maximumListeningDuration,
                                in: 8...45,
                                step: 1
                            )
                        }

                        LabeledContent("macOS voice speed") {
                            Stepper(
                                "\(Int(model.voiceTurnSettings.macSpeechRate))",
                                value: $model.voiceTurnSettings.macSpeechRate,
                                in: 145...230,
                                step: 5
                            )
                        }

                        Text("Lower silence delay feels faster. Raise it if Earth cuts you off before you finish speaking.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(18)
        }
        .onAppear(perform: syncLocalState)
        .onChange(of: model.providerConfig.modelName) { selectedModel = $0 }
        .onChange(of: model.voiceConfig.modelName) { selectedVoiceModel = $0 }
        .onChange(of: model.voiceConfig.voiceID) { selectedVoiceID = $0 }
        .onChange(of: model.availableModels) { models in
            if !models.contains(selectedModel), let first = models.first {
                selectedModel = first
                model.setSelectedModel(first)
            }
        }
    }

    private func syncLocalState() {
        selectedProviderID = model.providerConfig.providerID ?? ProviderCatalog.provider(matchingName: model.providerConfig.providerName).id
        customProviderName = model.providerConfig.providerName
        selectedModel = model.providerConfig.modelName
        baseURL = model.providerConfig.baseURL
        selectedVoiceProviderID = model.voiceConfig.providerID
        selectedVoiceModel = model.voiceConfig.modelName
        selectedVoiceID = model.voiceConfig.voiceID
        voiceBaseURL = model.voiceConfig.baseURL
        if !model.availableModels.contains(selectedModel) {
            model.availableModels.append(selectedModel)
            model.availableModels.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
    }

    private func saveSettings() {
        let cleanModel = selectedModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelName = cleanModel.isEmpty ? model.providerConfig.modelName : cleanModel
        let config = ProviderConfiguration(
            providerID: selectedProviderID,
            providerName: customProviderName.trimmingCharacters(in: .whitespacesAndNewlines),
            modelName: modelName,
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        model.saveProviderSettings(config: config, apiKey: apiKey)
        model.refreshModels(apiKeyFromField: apiKey)
        apiKey = ""
    }

    private func saveVoiceSettings() {
        let provider = VoiceProviderCatalog.provider(id: selectedVoiceProviderID)
        let config = VoiceConfiguration(
            providerID: selectedVoiceProviderID,
            providerName: provider.name,
            modelName: selectedVoiceModel.trimmingCharacters(in: .whitespacesAndNewlines),
            voiceID: selectedVoiceID.trimmingCharacters(in: .whitespacesAndNewlines),
            baseURL: voiceBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        model.saveVoiceSettings(config: config, apiKey: voiceAPIKey)
        voiceAPIKey = ""
    }
}

private struct SafetyView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Control and privacy",
                    subtitle: "Earth should be useful without ever feeling like it has taken over your Mac."
                )

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("First-run readiness")
                                .font(.headline)
                            Spacer()
                            if model.hasCompletedOnboarding {
                                Label("Done", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Button("Mark Done") {
                                    model.completeOnboarding()
                                }
                            }
                        }

                        HealthRow(title: "AI provider", detail: model.hasSavedAPIKey ? "API key saved" : "Add key in Settings", state: model.hasSavedAPIKey ? .ready : .actionNeeded)
                        HealthRow(title: "Model", detail: model.providerConfig.modelName.isEmpty ? "Choose a model" : model.providerConfig.modelName, state: model.providerConfig.modelName.isEmpty ? .actionNeeded : .ready)
                        HealthRow(title: "Accessibility", detail: model.computerControlStatus, state: model.computerControlStatus.hasPrefix("Ready") ? .ready : .warning)
                    }
                }

                PermissionDoctorCard()

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Safety mode", selection: Binding(
                            get: { model.safetyMode },
                            set: { model.setSafetyMode($0) }
                        )) {
                            ForEach(SafetyMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }

                        Text(model.safetyMode.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        SafetyRow(text: "Stop cancels listening, speech, and active tasks.")
                        SafetyRow(text: "Moving the real mouse pauses AI cursor work.")
                        SafetyRow(text: "Posting, sending, purchases, deletes, and account changes require confirmation.")
                        SafetyRow(text: "API keys are stored in macOS Keychain and are not written to logs.")
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Computer control")
                                .font(.headline)
                            Spacer()
                            Button("Check") {
                                model.refreshComputerControlStatus(prompt: false)
                            }
                            Button("Inspect UI") {
                                model.submitUserText("Inspect visible UI elements.")
                            }
                            Button("Grant Permission") {
                                model.openAccessibilitySettings()
                            }
                        }

                        HealthRow(
                            title: "Accessibility",
                            detail: model.computerControlStatus,
                            state: model.computerControlStatus.hasPrefix("Ready") ? .ready : .warning
                        )
                        HealthRow(
                            title: "Active app",
                            detail: model.activeApplicationName,
                            state: .ready
                        )

                        Text("Current safe tools: active app check, browser search, browser/UI inspection, confirmed result opening, numbered element click after confirmation, type into focused field, common keyboard shortcuts, screen help, notes, and local website creation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Natural commands: Inspect browser. Open result 1. Click element 1. Draft a message. Summarize my clipboard.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if !model.computerControlStatus.hasPrefix("Ready") {
                            Text("If Earth Agent is already listed in Accessibility, turn it off and on once, then reopen the app. macOS can keep the old permission after an app reinstall.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        if !model.visibleElements.isEmpty {
                            Divider()
                            Text("Latest visible elements")
                                .font(.caption.weight(.semibold))
                            ForEach(model.visibleElements.prefix(8)) { element in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("#\(element.id)")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(element.displayName)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                        Text("\(element.role) • \(element.canPress ? "clickable" : "visible") • \(element.frameDescription)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            Text("To click one: say 'Click element 1'.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Memory")
                            .font(.headline)
                        Text("Earth remembers only what you explicitly save here or say with 'remember'.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            TextField("Example: I prefer short, direct answers", text: $model.memoryDraft)
                                .textFieldStyle(.roundedBorder)
                            Button("Remember") {
                                model.rememberDraft()
                            }
                            .disabled(model.memoryDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        ForEach(model.memories.prefix(6)) { memory in
                            HStack {
                                Text(memory.text)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Button(role: .destructive) {
                                    model.deleteMemory(memory)
                                } label: {
                                    Image(systemName: "xmark.circle")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Permissions and logs")
                                .font(.headline)
                            Spacer()
                            Button {
                                model.openAccessibilitySettings()
                            } label: {
                                Label("Accessibility", systemImage: "gearshape.fill")
                            }
                        }

                        Text(model.permissionMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(model.logs.count) recent log entries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                model.exportDiagnosticsReport()
                            } label: {
                                Label("Export Report", systemImage: "square.and.arrow.down")
                            }
                            Button(role: .destructive) {
                                model.deleteMemoryAndLogs()
                            } label: {
                                Label("Delete Logs & Memory", systemImage: "trash")
                            }
                        }

                        Text(model.diagnosticsExportStatus)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(model.logs.prefix(80)) { entry in
                                    Text("\(entry.createdAt.formatted(date: .omitted, time: .standard))  \(entry.message)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                }
            }
            .padding(18)
        }
    }

}

private struct PermissionDoctorCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Permission doctor")
                        .font(.headline)
                    Spacer()
                    Button("Check") {
                        model.refreshPrivacyPermissionStatus()
                        model.refreshComputerControlStatus(prompt: false)
                    }
                }

                PermissionActionRow(
                    title: "Microphone",
                    detail: model.microphonePermissionDetail,
                    state: model.microphonePermissionState,
                    requestTitle: "Request Mic",
                    onRequest: { model.requestMicrophonePermission() },
                    onOpen: { model.openPrivacySettings(.microphone) }
                )

                PermissionActionRow(
                    title: "Speech",
                    detail: model.speechPermissionDetail,
                    state: model.speechPermissionState,
                    requestTitle: "Request Speech",
                    onRequest: { model.requestSpeechPermission() },
                    onOpen: { model.openPrivacySettings(.speechRecognition) }
                )

                PermissionActionRow(
                    title: "Screen Recording",
                    detail: model.screenRecordingPermissionDetail,
                    state: model.screenRecordingPermissionState,
                    requestTitle: "Request Screen",
                    onRequest: { model.requestScreenRecordingPermission() },
                    onOpen: { model.openPrivacySettings(.screenRecording) }
                )

                PermissionActionRow(
                    title: "Accessibility",
                    detail: model.computerControlStatus,
                    state: model.computerControlStatus.hasPrefix("Ready") ? .ready : .warning,
                    requestTitle: "Request Control",
                    onRequest: { model.openAccessibilitySettings() },
                    onOpen: { model.openPrivacySettings(.accessibility) }
                )
            }
        }
    }
}

private struct PermissionActionRow: View {
    let title: String
    let detail: String
    let state: ReadinessItem.State
    let requestTitle: String
    let onRequest: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(requestTitle, action: onRequest)
                .font(.caption)
                .buttonStyle(.borderless)

            Button("Open Settings", action: onOpen)
                .font(.caption)
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    private var color: Color {
        switch state {
        case .ready: .green
        case .warning: .orange
        case .actionNeeded: .red
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct HealthRow: View {
    let title: String
    let detail: String
    let state: ReadinessItem.State

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(width: 86, alignment: .leading)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer()
        }
    }

    private var color: Color {
        switch state {
        case .ready: .green
        case .warning: .yellow
        case .actionNeeded: .red
        }
    }
}

private struct SafetyRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatusPill: View {
    let status: AppStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status.rawValue)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .idle, .completed: .green
        case .listening: .mint
        case .thinking, .working: .blue
        case .waitingForConfirmation: .orange
        case .failed, .stopped: .red
        case .paused: .yellow
        }
    }
}

private struct EarthMiniIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.cyan, .blue], center: .topLeading, startRadius: 2, endRadius: size / 1.7))
            Image(systemName: "globe.americas.fill")
                .foregroundStyle(.white.opacity(0.92))
                .font(.system(size: size * 0.56))
        }
        .frame(width: size, height: size)
    }
}
