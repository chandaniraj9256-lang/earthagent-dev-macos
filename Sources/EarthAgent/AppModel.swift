import AppKit
import AVFoundation
import Combine
import Foundation
import PDFKit
import ServiceManagement
import Speech
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published var status: AppStatus = .idle
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Hi, I am Earth Agent. Ask me to open an app, open a website, draft something, or explain what I can do.")
    ]
    @Published var providerConfig: ProviderConfiguration
    @Published var providers: [ProviderProfile] = ProviderCatalog.providers
    @Published var voiceConfig: VoiceConfiguration
    @Published var voiceProviders: [VoiceProviderProfile] = VoiceProviderCatalog.providers
    @Published var availableModels: [String] = []
    @Published var availableVoiceModels: [String] = VoiceProviderCatalog.provider(id: "macos").models
    @Published var availableVoiceIDs: [String] = VoiceProviderCatalog.provider(id: "macos").voices
    @Published var modelRefreshStatus: String = "Choose a provider, then refresh models."
    @Published var providerTestStatus: String = "Provider not tested yet."
    @Published var voiceAPIKeyStatus: String = "Using macOS voice"
    @Published var voiceTestStatus: String = "Voice not tested yet."
    @Published var isRefreshingModels = false
    @Published var isTestingProvider = false
    @Published var apiKeyStatus: String = "No API key saved"
    @Published var typedMessage: String = ""
    @Published var pendingAttachments: [ChatAttachment] = []
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var isConversationMode = false
    @Published var voiceTurnState: VoiceTurnState = .idle
    @Published var voiceHint: String = "Tap the waveform for live conversation."
    @Published var voiceTurnSettings: VoiceTurnSettings = .standard {
        didSet {
            guard oldValue != voiceTurnSettings else { return }
            voiceTurnSettingsStore.save(voiceTurnSettings)
        }
    }
    @Published var voiceSessionTurns: [ConversationTurn] = []
    @Published var isTaskPaused = false
    @Published var isTaskStopped = false
    @Published var pendingConfirmation: AgentTask?
    @Published var logs: [LocalLogEntry] = []
    @Published var taskHistory: [TaskHistoryEntry] = []
    @Published var memories: [UserMemoryEntry] = []
    @Published var memoryDraft: String = ""
    @Published var memoryCategoryDraft: UserMemoryEntry.Category = .preferences
    @Published var safetyMode: SafetyMode = .autopilotSafe
    @Published var skillCards: [SkillCard] = SkillCard.defaults
    @Published var aiCursorVisible = false
    @Published var aiCursorPosition: CGPoint = .zero
    @Published var currentActivity: String?
    @Published var permissionMessage = "Earth Agent can open apps and websites now. UI reading and controlled clicking require Accessibility permission in System Settings."
    @Published var computerControlStatus: String = "Computer control not checked yet."
    @Published var activeApplicationName: String = "Unknown app"
    @Published var visibleElements: [AccessibilityElementSnapshot] = []
    @Published var activeTaskTitle: String?
    @Published var taskRunSteps: [TaskRunStep] = []
    @Published var latestPlan: AgentTask?
    @Published var browserCandidates: [BrowserResultCandidate] = []
    @Published var recentNotes: [SavedNoteSummary] = []
    @Published var hasCompletedOnboarding = false
    @Published var routines: [AgentRoutine] = []
    @Published var routineStatus: String = "Routines are local and require confirmation before running."
    @Published var subagentProfiles: [SubagentProfile] = SubagentProfile.defaults
    @Published var subagentRuns: [SubagentRun] = []
    @Published var mcpConnectors: [MCPConnectorProfile] = []
    @Published var mcpStatusText: String = "MCP connector foundation installed. No connector is active until enabled."
    @Published var agentTools: [AgentToolDescriptor] = []
    @Published var earthSkills: [EarthSkill] = []
    @Published var skillMatches: [SkillMatch] = []
    @Published var queuedPrompts: [PromptQueueEntry] = []
    @Published var sessionArchive: [SessionArchiveEntry] = []
    @Published var sessionSearchQuery: String = ""
    @Published var sessionSearchResults: [SessionSearchResult] = []
    @Published var voiceDiagnostics: [VoiceDiagnosticItem] = []
    @Published var socialConnectors: [SocialConnectorProfile] = []
    @Published var socialStatusText: String = "Social connectors are off until configured."
    @Published var computerUseReport: AdvancedComputerUseReport?
    @Published var shortcutStatus: String = "Shortcuts ready: Control-Option-Space to talk, Control-Option-M for minibar."
    @Published var launchAtLoginEnabled = false
    @Published var launchAtLoginStatus = "Login startup status not checked yet."
    @Published var microphonePermissionDetail = "Microphone permission not checked yet."
    @Published var microphonePermissionState: ReadinessItem.State = .warning
    @Published var speechPermissionDetail = "Speech recognition permission not checked yet."
    @Published var speechPermissionState: ReadinessItem.State = .warning
    @Published var screenRecordingPermissionDetail = "Screen Recording permission not checked yet."
    @Published var screenRecordingPermissionState: ReadinessItem.State = .warning
    @Published var diagnosticsExportStatus = "Diagnostics report not exported yet."

    private let settingsStore: ProviderSettingsStore
    private let voiceSettingsStore: VoiceSettingsStore
    private let speechInput: SpeechInputService
    private let speechOutput: SpeechOutputService
    private let automation: AutomationService
    private let planner: AgentPlanner
    private let logStore: LogStore
    private let taskHistoryStore: TaskHistoryStore
    private let launchAtLoginService: LaunchAtLoginService
    private let modelDiscovery: ModelDiscoveryService
    private let memoryStore: MemoryStore
    private let websiteBuilder: WebsiteBuilderService
    private let computerControl: ComputerControlService
    private let taskRunner: TaskRunnerService
    private let browserUse: BrowserUseService
    private let clipboard: ClipboardService
    private let noteWriter: NoteWriterService
    private let routineStore: RoutineStore
    private let routineService: RoutineService
    private let subagentCoordinator: SubagentCoordinator
    private let mcpConnectorStore: MCPConnectorStore
    private let mcpConnectorService: MCPConnectorService
    private let promptQueueStore: PromptQueueStore
    private let skillStore: EarthSkillStore
    private let skillMatcher: EarthSkillMatcher
    private let sessionArchiveStore: SessionArchiveStore
    private let socialConnectorStore: SocialConnectorStore
    private let socialConnectorService: SocialConnectorService
    private let voiceTurnSettingsStore = VoiceTurnSettingsStore()
    private var currentTask: Task<Void, Never>?
    private var silenceTask: Task<Void, Never>?
    private var listeningTimeoutTask: Task<Void, Never>?
    private var statusResetTask: Task<Void, Never>?
    private var routineMonitorTask: Task<Void, Never>?
    private var activeTaskHistoryID: UUID?
    private var userControlBaseline: CGPoint?
    private var userControlArmedAt: Date?
    private var lastConversationSubmittedText = ""
    private var conversationSendGeneration = 0
    private var listeningSessionGeneration = 0
    private var speechSessionGeneration = 0
    private var speechWatchdogTask: Task<Void, Never>?

    var hasSavedAPIKey: Bool {
        apiKeyStatus.lowercased().contains("saved")
    }

    var isProviderConnected: Bool {
        providerTestStatus.lowercased().hasPrefix("connected")
    }

    var readinessItems: [ReadinessItem] {
        [
            ReadinessItem(
                id: "provider",
                title: "Provider",
                detail: hasSavedAPIKey ? providerConfig.providerName : "Add an API key",
                state: hasSavedAPIKey ? .ready : .actionNeeded
            ),
            ReadinessItem(
                id: "model",
                title: "Model",
                detail: providerConfig.modelName.isEmpty ? "Select model" : providerConfig.modelName,
                state: providerConfig.modelName.isEmpty ? .actionNeeded : .ready
            ),
            ReadinessItem(
                id: "connection",
                title: "Connection",
                detail: isProviderConnected ? "Tested" : "Not tested",
                state: isProviderConnected ? .ready : .warning
            ),
            ReadinessItem(
                id: "voice",
                title: "Voice",
                detail: voiceConfig.providerID == "macos" ? "macOS voice" : voiceConfig.providerName,
                state: voiceConfig.providerID == "macos" || voiceAPIKeyStatus.contains("saved") ? .ready : .warning
            ),
            ReadinessItem(
                id: "computer",
                title: "Computer",
                detail: computerControlStatus.hasPrefix("Ready") ? "Control ready" : "Needs permission",
                state: computerControlStatus.hasPrefix("Ready") ? .ready : .warning
            )
        ]
    }

    var setupNeedsAttention: Bool {
        !hasSavedAPIKey || providerConfig.modelName.isEmpty || !isProviderConnected
    }

    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    var launchReadiness: LaunchReadinessSummary {
        let items = launchReadinessItems
        let weightedScore = items.reduce(0) { partial, item in
            switch item.state {
            case .ready:
                return partial + 2
            case .warning:
                return partial + 1
            case .actionNeeded:
                return partial
            }
        }
        let maxScore = max(items.count * 2, 1)
        let score = Int((Double(weightedScore) / Double(maxScore) * 100).rounded())
        let label: String
        let detail: String
        if score >= 85 {
            label = "Launch-ready foundation"
            detail = "Earth is ready for serious local testing."
        } else if score >= 65 {
            label = "Almost ready"
            detail = "A few setup items still reduce reliability."
        } else {
            label = "Needs setup"
            detail = "Finish the action-needed items before relying on Earth."
        }
        return LaunchReadinessSummary(score: score, label: label, detail: detail, items: items)
    }

    private var launchReadinessItems: [LaunchReadinessItem] {
        [
            LaunchReadinessItem(
                id: "provider",
                title: "AI provider connected",
                detail: isProviderConnected ? providerConfig.providerName : "Save and test an AI provider in Settings.",
                state: isProviderConnected ? .ready : .actionNeeded,
                category: .ai
            ),
            LaunchReadinessItem(
                id: "model",
                title: "Model selected",
                detail: providerConfig.modelName.isEmpty ? "Choose a model returned by the provider." : providerConfig.modelName,
                state: providerConfig.modelName.isEmpty ? .actionNeeded : .ready,
                category: .ai
            ),
            LaunchReadinessItem(
                id: "voice",
                title: "Voice output ready",
                detail: voiceConfig.providerID == "macos" ? "Using macOS voice." : voiceConfig.providerName,
                state: voiceConfig.providerID == "macos" || voiceAPIKeyStatus.contains("saved") ? .ready : .warning,
                category: .voice
            ),
            LaunchReadinessItem(
                id: "mic",
                title: "Microphone",
                detail: microphonePermissionDetail,
                state: microphonePermissionState,
                category: .permissions
            ),
            LaunchReadinessItem(
                id: "speech",
                title: "Speech Recognition",
                detail: speechPermissionDetail,
                state: speechPermissionState,
                category: .permissions
            ),
            LaunchReadinessItem(
                id: "screen",
                title: "Screen Recording",
                detail: screenRecordingPermissionDetail,
                state: screenRecordingPermissionState,
                category: .permissions
            ),
            LaunchReadinessItem(
                id: "accessibility",
                title: "Accessibility",
                detail: computerControlStatus,
                state: computerControlStatus.hasPrefix("Ready") ? .ready : .warning,
                category: .permissions
            ),
            LaunchReadinessItem(
                id: "safety",
                title: "Safety mode",
                detail: safetyMode.rawValue,
                state: safetyMode == .chatOnly ? .warning : .ready,
                category: .safety
            ),
            LaunchReadinessItem(
                id: "history",
                title: "Task history",
                detail: "Local audit trail is enabled.",
                state: .ready,
                category: .safety
            ),
            LaunchReadinessItem(
                id: "shortcuts",
                title: "Global shortcuts",
                detail: shortcutStatus,
                state: .ready,
                category: .background
            ),
            LaunchReadinessItem(
                id: "login",
                title: "Start at login",
                detail: launchAtLoginStatus,
                state: launchAtLoginEnabled ? .ready : .warning,
                category: .background
            ),
            LaunchReadinessItem(
                id: "onboarding",
                title: "First-run checklist",
                detail: hasCompletedOnboarding ? "Completed." : "Still visible until setup is reviewed.",
                state: hasCompletedOnboarding ? .ready : .warning,
                category: .product
            )
        ]
    }

    init(
        settingsStore: ProviderSettingsStore,
        voiceSettingsStore: VoiceSettingsStore,
        speechInput: SpeechInputService,
        speechOutput: SpeechOutputService,
        automation: AutomationService,
        planner: AgentPlanner,
        logStore: LogStore,
        taskHistoryStore: TaskHistoryStore,
        launchAtLoginService: LaunchAtLoginService,
        modelDiscovery: ModelDiscoveryService,
        memoryStore: MemoryStore,
        websiteBuilder: WebsiteBuilderService,
        computerControl: ComputerControlService,
        taskRunner: TaskRunnerService,
        browserUse: BrowserUseService,
        clipboard: ClipboardService,
        noteWriter: NoteWriterService,
        routineStore: RoutineStore,
        routineService: RoutineService,
        subagentCoordinator: SubagentCoordinator,
        mcpConnectorStore: MCPConnectorStore,
        mcpConnectorService: MCPConnectorService,
        promptQueueStore: PromptQueueStore,
        skillStore: EarthSkillStore,
        skillMatcher: EarthSkillMatcher,
        sessionArchiveStore: SessionArchiveStore,
        socialConnectorStore: SocialConnectorStore,
        socialConnectorService: SocialConnectorService
    ) {
        self.settingsStore = settingsStore
        self.voiceSettingsStore = voiceSettingsStore
        self.speechInput = speechInput
        self.speechOutput = speechOutput
        self.automation = automation
        self.planner = planner
        self.logStore = logStore
        self.taskHistoryStore = taskHistoryStore
        self.launchAtLoginService = launchAtLoginService
        self.modelDiscovery = modelDiscovery
        self.memoryStore = memoryStore
        self.websiteBuilder = websiteBuilder
        self.computerControl = computerControl
        self.taskRunner = taskRunner
        self.browserUse = browserUse
        self.clipboard = clipboard
        self.noteWriter = noteWriter
        self.routineStore = routineStore
        self.routineService = routineService
        self.subagentCoordinator = subagentCoordinator
        self.mcpConnectorStore = mcpConnectorStore
        self.mcpConnectorService = mcpConnectorService
        self.promptQueueStore = promptQueueStore
        self.skillStore = skillStore
        self.skillMatcher = skillMatcher
        self.sessionArchiveStore = sessionArchiveStore
        self.socialConnectorStore = socialConnectorStore
        self.socialConnectorService = socialConnectorService
        self.providerConfig = settingsStore.loadConfiguration()
        self.voiceConfig = voiceSettingsStore.loadConfiguration()
        self.voiceTurnSettings = voiceTurnSettingsStore.load()
        self.apiKeyStatus = settingsStore.hasAPIKey ? "API key saved in Keychain" : "No API key saved"
        self.voiceAPIKeyStatus = voiceConfig.providerID == "macos"
            ? "Using macOS voice"
            : (voiceSettingsStore.hasAPIKey ? "Voice API key saved in Keychain" : "No voice API key saved")
        self.logs = logStore.load()
        self.taskHistory = taskHistoryStore.load()
        self.memories = memoryStore.load()
        self.safetyMode = SafetyMode(rawValue: UserDefaults.standard.string(forKey: "earth-agent-safety-mode") ?? "") ?? .autopilotSafe
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "earth-agent-onboarding-complete")
        let provider = ProviderCatalog.provider(id: providerConfig.providerID)
        self.availableModels = normalizedModels([providerConfig.modelName] + provider.fallbackModels)
        let voiceProvider = VoiceProviderCatalog.provider(id: voiceConfig.providerID)
        self.availableVoiceModels = normalizedModels([voiceConfig.modelName] + voiceProvider.models)
        self.availableVoiceIDs = voiceConfig.providerID == "macos"
            ? normalizedModels([voiceConfig.voiceID] + speechOutput.availableMacVoiceIDs())
            : normalizedModels([voiceConfig.voiceID] + voiceProvider.voices)
        self.routines = routineStore.load().map { routineService.withNextRun($0) }
        self.mcpConnectors = mcpConnectorStore.load()
        self.mcpStatusText = mcpConnectorService.statusReport(connectors: self.mcpConnectors)
        self.earthSkills = skillStore.load()
        self.queuedPrompts = promptQueueStore.load()
        self.sessionArchive = sessionArchiveStore.load()
        self.socialConnectors = socialConnectorStore.load().map { connector in
            var copy = connector
            copy.botTokenSaved = socialConnectorStore.hasSecret(for: connector)
            copy.status = socialConnectorService.validationStatus(for: copy)
            return copy
        }
        self.socialStatusText = socialConnectorService.statusReport(connectors: self.socialConnectors)
        refreshComputerControlStatus(prompt: false)
        refreshLaunchAtLoginStatus()
        refreshPrivacyPermissionStatus()
        updateAdvancedComputerUseReport()
        refreshAgentTools()
        refreshVoiceDiagnostics()
        startRoutineMonitor()
    }

    func sendTypedMessage() {
        let text = typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = pendingAttachments
        guard !text.isEmpty || !attachments.isEmpty else { return }
        typedMessage = ""
        pendingAttachments = []
        submitUserText(text, attachments: attachments)
    }

    func submitUserText(_ text: String, attachments: [ChatAttachment] = []) {
        stopSpeaking()
        statusResetTask?.cancel()
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let requestText = cleanText.isEmpty ? "Review the attached file\(attachments.count == 1 ? "" : "s")." : cleanText
        let lowered = requestText.lowercased()
        if isStopCommand(lowered) {
            stopAll()
            return
        }
        if isPauseCommand(lowered) {
            pauseTask()
            return
        }
        if lowered == "continue" || lowered == "resume" {
            resumeTask()
            return
        }
        if lowered.contains("remember ") || lowered.hasPrefix("remember") {
            let memory = requestText
                .replacingOccurrences(of: "remember that", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "remember", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !memory.isEmpty {
                remember(memory)
                return
            }
        }
        if let routine = routineFromRunCommand(lowered) {
            runRoutine(routine, recordUserMessage: false)
            return
        }

        if shouldQueuePrompt {
            enqueuePrompt(text: requestText, attachments: attachments)
            return
        }

        pendingConfirmation = nil
        isTaskStopped = false
        isTaskPaused = false
        messages.append(ChatMessage(role: .user, content: requestText, attachments: attachments))
        archiveMessage(role: .user, text: requestText, attachments: attachments)
        appendLog("User: \(requestText)")
        if isConversationMode {
            rememberVoiceTurn(role: .user, text: requestText)
        }
        if !attachments.isEmpty {
            appendLog("Attachments: \(attachments.map(\.name).joined(separator: ", "))")
        }
        skillMatches = skillMatcher.matches(for: requestText, skills: earthSkills)

        currentTask?.cancel()
        currentTask = Task { [weak self] in
            await self?.handleUserText(requestText, attachments: attachments)
        }
    }

    private var shouldQueuePrompt: Bool {
        switch status {
        case .thinking, .working:
            return true
        default:
            return false
        }
    }

    private func enqueuePrompt(text: String, attachments: [ChatAttachment]) {
        let entry = PromptQueueEntry(text: text, attachments: attachments)
        queuedPrompts.append(entry)
        promptQueueStore.save(queuedPrompts)
        appendLog("Queued prompt: \(text)")
        appendAssistant("Queued: \(text)\n\nI will run this after the current task finishes.", shouldSpeak: false)
    }

    func removeQueuedPrompt(_ entry: PromptQueueEntry) {
        queuedPrompts.removeAll { $0.id == entry.id }
        promptQueueStore.save(queuedPrompts)
        appendLog("Removed queued prompt.")
    }

    func promoteQueuedPrompt(_ entry: PromptQueueEntry) {
        guard let index = queuedPrompts.firstIndex(where: { $0.id == entry.id }), index > 0 else { return }
        let item = queuedPrompts.remove(at: index)
        queuedPrompts.insert(item, at: 0)
        promptQueueStore.save(queuedPrompts)
        appendLog("Promoted queued prompt.")
    }

    private func drainPromptQueueSoon() {
        guard !queuedPrompts.isEmpty else { return }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            await MainActor.run {
                guard let self, !self.queuedPrompts.isEmpty else { return }
                guard self.status == .completed || self.status == .failed || self.status == .idle else { return }
                let next = self.queuedPrompts.removeFirst()
                self.promptQueueStore.save(self.queuedPrompts)
                self.submitUserText(next.text, attachments: next.attachments)
            }
        }
    }

    private func archiveMessage(role: ChatMessage.Role, text: String, attachments: [ChatAttachment] = []) {
        let entry = SessionArchiveEntry(
            role: role,
            text: text,
            attachmentNames: attachments.map(\.name)
        )
        sessionArchive = sessionArchiveStore.append(entry, to: sessionArchive)
        if !sessionSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchSessions()
        }
    }

    func searchSessions() {
        sessionSearchResults = sessionArchiveStore.search(sessionSearchQuery, in: sessionArchive)
    }

    func continueFromSearchResult(_ result: SessionSearchResult) {
        let prompt = "Continue from this previous \(result.entry.role.rawValue) message:\n\n\(result.entry.text)"
        submitUserText(prompt)
    }

    func refreshAgentTools() {
        agentTools = AgentToolCatalog.descriptors(
            hasProvider: hasSavedAPIKey && !providerConfig.modelName.isEmpty,
            accessibilityReady: computerControlStatus.hasPrefix("Ready"),
            screenRecordingReady: screenRecordingPermissionState == .ready,
            mcpEnabledCount: mcpConnectors.filter(\.isEnabled).count,
            socialEnabledCount: socialConnectors.filter(\.isEnabled).count
        )
    }

    func refreshVoiceDiagnostics() {
        voiceDiagnostics = [
            VoiceDiagnosticItem(
                id: "microphone",
                layer: .microphone,
                detail: microphonePermissionDetail,
                state: microphonePermissionState
            ),
            VoiceDiagnosticItem(
                id: "stt",
                layer: .speechToText,
                detail: speechPermissionDetail,
                state: speechPermissionState
            ),
            VoiceDiagnosticItem(
                id: "model",
                layer: .aiModel,
                detail: isProviderConnected ? "Connected to \(providerConfig.providerName)." : providerTestStatus,
                state: isProviderConnected ? .ready : .warning
            ),
            VoiceDiagnosticItem(
                id: "tts",
                layer: .textToSpeech,
                detail: voiceConfig.providerID == "macos" ? "Using macOS system voice." : voiceAPIKeyStatus,
                state: voiceConfig.providerID == "macos" || voiceAPIKeyStatus.contains("saved") ? .ready : .warning
            ),
            VoiceDiagnosticItem(
                id: "playback",
                layer: .playback,
                detail: voiceTestStatus,
                state: voiceTestStatus.contains("played") || voiceConfig.providerID == "macos" ? .ready : .warning
            ),
            VoiceDiagnosticItem(
                id: "interruption",
                layer: .interruption,
                detail: "Stop button and speech interruption are wired.",
                state: .ready
            )
        ]
    }

    func chooseAttachments() {
        let panel = NSOpenPanel()
        panel.title = "Choose photos, videos, or files"
        panel.prompt = "Attach"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true

        if panel.runModal() == .OK {
            attachFiles(panel.urls)
        }
    }

    func attachFiles(_ urls: [URL]) {
        addAttachments(from: urls)
    }

    func removePendingAttachment(_ attachment: ChatAttachment) {
        pendingAttachments.removeAll { $0.id == attachment.id }
    }

    func captureScreenAttachment() {
        do {
            let attachment = try captureScreenAttachmentObject()
            pendingAttachments = normalizedAttachments(pendingAttachments + [attachment])
            appendLog("Captured screen attachment: \(attachment.name)")
        } catch {
            appendAssistant("I could not capture the screen: \(error.localizedDescription)", shouldSpeak: false)
            appendLog("Screen capture failed: \(error.localizedDescription)")
        }
    }

    private func captureScreenAttachmentObject() throws -> ChatAttachment {
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            throw NSError(
                domain: "EarthAgent.ScreenCapture",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "macOS may need Screen Recording permission for Earth Agent."]
            )
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EarthAgent-Screenshots", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let file = directory.appendingPathComponent("earth-screen-\(formatter.string(from: Date())).png")
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "EarthAgent.ScreenCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create screenshot PNG."])
        }

        try data.write(to: file, options: .atomic)
        return makeAttachment(from: file)
    }

    func startListening() {
        guard !isListening else { return }
        refreshPrivacyPermissionStatus()
        let authorization = speechInput.authorizationSnapshot()
        if authorization.hasDeniedPermission {
            handleListeningFailure(permissionGuidance(for: authorization))
            return
        }
        if isSpeaking {
            stopSpeaking()
            voiceTurnState = .interrupted
            appendLog("Speech interrupted by user.")
        }
        status = .listening
        isListening = true
        voiceTurnState = .listening
        if authorization.isFullyAuthorized {
            voiceHint = isConversationMode ? "Listening. Pause when you are done." : "Listening. Press send when ready."
        } else {
            voiceHint = "Requesting microphone and speech access..."
        }
        lastConversationSubmittedText = ""
        listeningSessionGeneration += 1
        let listeningGeneration = listeningSessionGeneration
        appendLog("Voice listening started.")
        scheduleListeningTimeoutIfNeeded()
        speechInput.start { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                guard self.listeningSessionGeneration == listeningGeneration else { return }
                switch result {
                case .success(let update):
                    guard self.isListening else { return }
                    self.typedMessage = update.transcript
                    self.voiceTurnState = .listening
                    self.voiceHint = update.transcript.isEmpty ? "Listening. Speak naturally." : "Heard: \(update.transcript)"
                    if self.isConversationMode {
                        self.scheduleConversationAutoSend(isFinal: update.isFinal)
                    }
                case .failure(let error):
                    self.handleListeningFailure(error.localizedDescription)
                }
            }
        }
    }

    func toggleDictation() {
        if isListening {
            listeningSessionGeneration += 1
            speechInput.stop()
            isListening = false
            listeningTimeoutTask?.cancel()
            listeningTimeoutTask = nil
            status = .idle
            voiceTurnState = .idle
            voiceHint = "Dictation stopped."
            appendLog("Voice dictation stopped.")
        } else {
            isConversationMode = false
            startListening()
        }
    }

    func toggleConversationMode() {
        if isConversationMode {
            stopConversationMode()
        } else {
            startConversationMode()
        }
    }

    func startConversationMode() {
        guard !setupNeedsAttention else {
            appendAssistant("Conversation mode needs AI setup first. Click +, open Settings, save your API key, then press Test.", shouldSpeak: false)
            status = .failed
            scheduleStatusReset(after: 5)
            return
        }
        isConversationMode = true
        typedMessage = ""
        voiceSessionTurns = []
        voiceTurnState = .idle
        voiceHint = "Live Talk is on. Speak naturally."
        appendLog("Conversation mode started.")
        if isSpeaking {
            stopSpeaking()
        }
        if !isListening {
            startListening()
        }
    }

    func stopConversationMode() {
        isConversationMode = false
        listeningSessionGeneration += 1
        silenceTask?.cancel()
        silenceTask = nil
        listeningTimeoutTask?.cancel()
        listeningTimeoutTask = nil
        if isListening {
            speechInput.stop()
            isListening = false
        }
        if status == .listening {
            status = .idle
        }
        voiceTurnState = .stopped
        voiceHint = "Conversation mode stopped."
        appendLog("Conversation mode stopped.")
    }

    func stopListeningAndSend() {
        guard isListening else { return }
        listeningSessionGeneration += 1
        silenceTask?.cancel()
        silenceTask = nil
        listeningTimeoutTask?.cancel()
        listeningTimeoutTask = nil
        isListening = false
        speechInput.stop()
        appendLog("Voice listening stopped.")
        let text = typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            if isConversationMode && text.split(separator: " ").count < voiceTurnSettings.minimumWordCount {
                status = .listening
                voiceTurnState = .listening
                voiceHint = "I only caught a little. Keep going."
                startListening()
                return
            }
            voiceTurnState = .processing
            voiceHint = "Thinking..."
            sendTypedMessage()
        } else {
            status = .idle
            voiceTurnState = .idle
            voiceHint = "I did not hear anything."
        }
    }

    func stopAll() {
        currentTask?.cancel()
        currentTask = nil
        statusResetTask?.cancel()
        statusResetTask = nil
        invalidateSpeechSession()
        listeningSessionGeneration += 1
        isListening = false
        isSpeaking = false
        isConversationMode = false
        isTaskStopped = true
        isTaskPaused = false
        pendingConfirmation = nil
        aiCursorVisible = false
        currentActivity = nil
        activeTaskTitle = nil
        taskRunSteps = taskRunSteps.map { step in
            var copy = step
            if copy.state == .running || copy.state == .pending {
                copy.state = .blocked
                copy.detail = "Stopped by user"
            }
            return copy
        }
        silenceTask?.cancel()
        silenceTask = nil
        listeningTimeoutTask?.cancel()
        listeningTimeoutTask = nil
        speechInput.stop()
        speechOutput.stop()
        status = .stopped
        voiceTurnState = .stopped
        voiceHint = "Stopped."
        appendAssistant("Stopped. You are in control.", shouldSpeak: false)
        updateActiveTaskHistory(state: .cancelled, summary: "Stopped by user.")
        appendLog("Emergency stop pressed.")
    }

    func pauseTask() {
        isTaskPaused = true
        isTaskStopped = false
        status = .paused
        voiceTurnState = .paused
        voiceHint = "Paused."
        aiCursorVisible = false
        currentActivity = nil
        taskRunSteps = taskRunSteps.map { step in
            var copy = step
            if copy.state == .running || copy.state == .pending {
                copy.state = .blocked
                copy.detail = "Paused"
            }
            return copy
        }
        appendAssistant("Paused. Move the real mouse or press Stop anytime. Say Continue when you want me to resume.", shouldSpeak: false)
        updateActiveTaskHistory(state: .paused, summary: "Paused by user.")
        appendLog("Task paused.")
    }

    func resumeTask() {
        guard isTaskPaused else {
            appendAssistant("There is no paused task to resume.", shouldSpeak: false)
            return
        }
        isTaskPaused = false
        status = .idle
        appendAssistant("Ready. Please give the next command or repeat the task you want me to continue.", shouldSpeak: false)
        appendLog("Task resume requested.")
    }

    func pauseIfUserMovedMouse() {
        guard status == .working, aiCursorVisible, let baseline = userControlBaseline else { return }
        guard Date() >= (userControlArmedAt ?? .distantFuture) else { return }
        let current = NSEvent.mouseLocation
        let distance = hypot(current.x - baseline.x, current.y - baseline.y)
        if distance > 80 {
            pauseTask()
            appendLog("Task paused because the real mouse moved.")
        }
    }

    func confirmPendingTask() {
        guard let task = pendingConfirmation else { return }
        pendingConfirmation = nil
        updateActiveTaskHistory(state: .running, summary: "Confirmed by user and running.")
        appendLog("User confirmed task: \(task.explanation)")
        currentTask = Task { [weak self] in
            await self?.execute(task)
        }
    }

    func cancelPendingTask() {
        pendingConfirmation = nil
        status = .idle
        currentActivity = nil
        appendAssistant("Cancelled. I did not take that action.", shouldSpeak: false)
        updateActiveTaskHistory(state: .cancelled, summary: "Cancelled before running.")
        appendLog("User cancelled pending task.")
    }

    func saveProviderSettings(config: ProviderConfiguration, apiKey: String) {
        providerConfig = config
        settingsStore.saveConfiguration(config)
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                try settingsStore.saveAPIKey(apiKey)
                apiKeyStatus = "API key saved in Keychain"
                appendLog("Provider settings saved with a Keychain API key.")
            } catch {
                apiKeyStatus = "Could not save API key"
                appendAssistant("I could not save the API key: \(error.localizedDescription)")
            }
        } else {
            appendLog("Provider settings saved without changing API key.")
        }
        refreshAgentTools()
        refreshVoiceDiagnostics()
    }

    func testProviderConnection(apiKeyFromField: String? = nil) {
        guard !isTestingProvider else { return }
        isTestingProvider = true
        providerTestStatus = "Testing \(providerConfig.providerName)..."

        let config = providerConfig
        Task { [weak self] in
            guard let self else { return }
            do {
                let typedKey = apiKeyFromField?.trimmingCharacters(in: .whitespacesAndNewlines)
                let savedKey = typedKey?.isEmpty == false ? typedKey : try? self.settingsStore.loadAPIKey()
                let models = try await self.modelDiscovery.fetchModels(baseURL: config.baseURL, apiKey: savedKey)
                await MainActor.run {
                    self.providerTestStatus = "Connected. Found \(models.count) models."
                    self.isTestingProvider = false
                    self.refreshAgentTools()
                    self.refreshVoiceDiagnostics()
                    self.appendLog("Provider test succeeded for \(config.providerName).")
                }
            } catch {
                await MainActor.run {
                    self.providerTestStatus = "Connection failed: \(error.localizedDescription)"
                    self.isTestingProvider = false
                    self.refreshVoiceDiagnostics()
                    self.appendLog("Provider test failed for \(config.providerName): \(error.localizedDescription)")
                }
            }
        }
    }

    func applyProviderSelection(_ provider: ProviderProfile) {
        providerConfig = ProviderConfiguration(
            providerID: provider.id,
            providerName: provider.name,
            modelName: provider.defaultModel,
            baseURL: provider.baseURL
        )
        availableModels = normalizedModels(provider.fallbackModels)
        modelRefreshStatus = provider.notes
        refreshAgentTools()
        refreshVoiceDiagnostics()
    }

    func setSelectedModel(_ modelName: String) {
        providerConfig.modelName = modelName
    }

    func applyVoiceProviderSelection(_ provider: VoiceProviderProfile) {
        voiceConfig = VoiceConfiguration(
            providerID: provider.id,
            providerName: provider.name,
            modelName: provider.defaultModel,
            voiceID: provider.defaultVoice,
            baseURL: provider.baseURL
        )
        availableVoiceModels = normalizedModels(provider.models)
        availableVoiceIDs = provider.id == "macos"
            ? normalizedModels(speechOutput.availableMacVoiceIDs())
            : normalizedModels(provider.voices)
        voiceTestStatus = provider.notes
    }

    func setSelectedVoiceModel(_ modelName: String) {
        voiceConfig.modelName = modelName
        refreshVoiceDiagnostics()
    }

    func setSelectedVoiceID(_ voiceID: String) {
        voiceConfig.voiceID = voiceID
        refreshVoiceDiagnostics()
    }

    func saveVoiceSettings(config: VoiceConfiguration, apiKey: String) {
        voiceConfig = config
        voiceSettingsStore.saveConfiguration(config)
        availableVoiceModels = normalizedModels([config.modelName] + VoiceProviderCatalog.provider(id: config.providerID).models)
        availableVoiceIDs = config.providerID == "macos"
            ? normalizedModels([config.voiceID] + speechOutput.availableMacVoiceIDs())
            : normalizedModels([config.voiceID] + VoiceProviderCatalog.provider(id: config.providerID).voices)

        if config.providerID == "macos" {
            voiceAPIKeyStatus = "Using macOS voice"
            voiceTestStatus = "macOS voice selected."
            appendLog("Voice provider set to macOS.")
            refreshVoiceDiagnostics()
            return
        }

        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                try voiceSettingsStore.saveAPIKey(apiKey)
                voiceAPIKeyStatus = "Voice API key saved in Keychain"
                appendLog("Voice provider settings saved with a Keychain API key.")
            } catch {
                voiceAPIKeyStatus = "Could not save voice API key"
                appendAssistant("I could not save the voice API key: \(error.localizedDescription)", shouldSpeak: false)
            }
        } else {
            voiceAPIKeyStatus = voiceSettingsStore.hasAPIKey ? "Voice API key saved in Keychain" : "No voice API key saved"
            appendLog("Voice provider settings saved without changing API key.")
        }
        refreshVoiceDiagnostics()
    }

    func testVoice(apiKeyFromField: String? = nil) {
        let typedKey = apiKeyFromField?.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedKey = typedKey?.isEmpty == false ? typedKey : try? voiceSettingsStore.loadAPIKey()
        voiceTestStatus = "Testing \(voiceConfig.providerName)..."
        let speechGeneration = beginSpeechSession(
            text: "Hi, I am Earth Agent. This is the selected voice.",
            hint: "Testing selected voice."
        )
        speechOutput.speak(
            "Hi, I am Earth Agent. This is the selected voice.",
            configuration: voiceConfig,
            rate: Float(voiceTurnSettings.macSpeechRate),
            apiKey: savedKey,
            onFallback: { [weak self] message in
                Task { @MainActor in
                    self?.voiceTestStatus = message
                    self?.refreshVoiceDiagnostics()
                    self?.appendLog("Voice test fallback: \(message)")
                }
            },
            completion: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    guard self.isSpeaking else { return }
                    self.finishSpeechSession(generation: speechGeneration, allowResumeListening: false)
                    if self.voiceTestStatus.hasPrefix("Testing") {
                        self.voiceTestStatus = "Voice test played."
                    }
                    self.refreshVoiceDiagnostics()
                }
            }
        )
    }

    func displayNameForVoiceID(_ voiceID: String) -> String {
        if voiceConfig.providerID == "macos" || voiceID.hasPrefix("com.apple.") {
            return speechOutput.macVoiceLabel(for: voiceID)
        }
        return voiceID
    }

    func refreshModels(apiKeyFromField: String? = nil) {
        guard !isRefreshingModels else { return }
        isRefreshingModels = true
        modelRefreshStatus = "Refreshing models from \(providerConfig.providerName)..."

        let config = providerConfig
        Task { [weak self] in
            guard let self else { return }
            do {
                let typedKey = apiKeyFromField?.trimmingCharacters(in: .whitespacesAndNewlines)
                let savedKey = typedKey?.isEmpty == false ? typedKey : try? self.settingsStore.loadAPIKey()
                let models = try await self.modelDiscovery.fetchModels(baseURL: config.baseURL, apiKey: savedKey)
                await MainActor.run {
                    self.availableModels = self.normalizedModels(models)
                    if !self.availableModels.contains(self.providerConfig.modelName), let first = self.availableModels.first {
                        self.providerConfig.modelName = first
                    }
                    self.modelRefreshStatus = "Loaded \(self.availableModels.count) models from \(config.providerName)."
                    self.isRefreshingModels = false
                    self.appendLog("Refreshed \(self.availableModels.count) models for \(config.providerName).")
                }
            } catch {
                await MainActor.run {
                    let fallback = ProviderCatalog.provider(id: config.providerID).fallbackModels
                    self.availableModels = self.normalizedModels([config.modelName] + fallback)
                    self.modelRefreshStatus = "Could not refresh live models: \(error.localizedDescription). Showing saved fallback models."
                    self.isRefreshingModels = false
                    self.appendLog("Model refresh failed for \(config.providerName): \(error.localizedDescription)")
                }
            }
        }
    }

    func deleteMemoryAndLogs() {
        logs.removeAll()
        logStore.save([])
        taskHistory.removeAll()
        activeTaskHistoryID = nil
        taskHistoryStore.save([])
        memories.removeAll()
        memoryStore.save([])
        messages.append(ChatMessage(role: .assistant, content: "Local logs, task history, and memory were deleted."))
    }

    func deleteLogsOnly() {
        logs.removeAll()
        logStore.save([])
        appendLog("Logs cleared.")
    }

    @discardableResult
    func exportDiagnosticsReport() -> URL? {
        let summary = launchReadiness
        do {
            let directory = try diagnosticsDirectoryURL()
            let file = directory.appendingPathComponent("earth-agent-diagnostics-\(diagnosticsTimestamp()).md")
            try diagnosticsMarkdown(summary: summary).write(to: file, atomically: true, encoding: .utf8)
            diagnosticsExportStatus = "Saved diagnostics report: \(file.lastPathComponent)"
            appendLog("Diagnostics report exported.")
            NSWorkspace.shared.activateFileViewerSelecting([file])
            return file
        } catch {
            diagnosticsExportStatus = "Could not export diagnostics: \(error.localizedDescription)"
            appendLog("Diagnostics export failed: \(error.localizedDescription)")
            return nil
        }
    }

    func clearTaskHistory() {
        taskHistory.removeAll()
        activeTaskHistoryID = nil
        taskHistoryStore.save([])
        appendLog("Task history cleared.")
    }

    func runSkill(_ skill: SkillCard) {
        if skill.requiresFuturePermission {
            appendAssistant("That skill needs screen-reading permission and the Accessibility tool layer. I can explain the plan now, but I will not inspect your screen in this build.", shouldSpeak: false)
        }
        submitUserText(skill.prompt)
    }

    func remember(_ text: String) {
        remember(text, category: memoryCategoryDraft)
    }

    func remember(_ text: String, category: UserMemoryEntry.Category) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard !looksLikeSensitiveMemory(clean) else {
            appendAssistant("I did not save that memory because it looks sensitive. Please do not store API keys, passwords, private financial data, or secrets in Earth memory.", shouldSpeak: false)
            appendLog("Blocked sensitive-looking memory.")
            return
        }
        memories.insert(UserMemoryEntry(text: clean, category: category), at: 0)
        memories = Array(memories.prefix(50))
        memoryStore.save(memories)
        appendAssistant("Remembered under \(category.rawValue): \(clean)", shouldSpeak: false)
        appendLog("Saved memory with user permission.")
    }

    func rememberDraft() {
        remember(memoryDraft)
        memoryDraft = ""
    }

    func deleteMemory(_ memory: UserMemoryEntry) {
        memories.removeAll { $0.id == memory.id }
        memoryStore.save(memories)
        appendLog("Deleted one memory.")
    }

    func updateMemory(_ memory: UserMemoryEntry, text: String, category: UserMemoryEntry.Category) {
        guard let index = memories.firstIndex(where: { $0.id == memory.id }) else { return }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard !looksLikeSensitiveMemory(clean) else {
            appendAssistant("I did not update that memory because it looks sensitive.", shouldSpeak: false)
            return
        }
        memories[index].text = clean
        memories[index].category = category
        memoryStore.save(memories)
        appendLog("Updated memory.")
    }

    func setSafetyMode(_ mode: SafetyMode) {
        safetyMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "earth-agent-safety-mode")
        appendLog("Safety mode changed to \(mode.rawValue).")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "earth-agent-onboarding-complete")
        appendLog("First-run onboarding dismissed.")
    }

    func runRoutine(_ routine: AgentRoutine, recordUserMessage: Bool = true) {
        currentTask?.cancel()
        pendingConfirmation = nil
        let task = routineTask(for: routine, requiresConfirmation: false)
        if recordUserMessage {
            messages.append(ChatMessage(role: .user, content: "Run routine: \(routine.title)"))
        }
        appendLog("User ran routine: \(routine.title)")
        currentTask = Task { [weak self] in
            await self?.execute(task)
        }
    }

    func toggleRoutine(_ routine: AgentRoutine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        routines[index].isEnabled.toggle()
        routines[index] = routineService.withNextRun(routines[index])
        routineStore.save(routines)
        routineStatus = routines[index].isEnabled
            ? "\(routines[index].title) is enabled. Earth will ask before running it."
            : "\(routines[index].title) is off."
        appendLog("Routine \(routines[index].title) toggled to \(routines[index].isEnabled ? "on" : "off").")
    }

    func createRoutine(title: String, prompt: String, schedule: AgentRoutine.Schedule = .manual) {
        let routine = routineService.withNextRun(
            AgentRoutine(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom routine" : title,
                prompt: prompt,
                schedule: schedule,
                isEnabled: false,
                requiresConfirmation: true,
                pinnedProviderName: providerConfig.providerName,
                pinnedModelName: providerConfig.modelName,
                attachedSkillID: skillMatches.first?.skill.id,
                toolset: skillMatches.first?.skill.category.rawValue ?? "Core"
            )
        )
        routines.insert(routine, at: 0)
        routineStore.save(routines)
        routineStatus = "Created \(routine.title). It is off until you enable it."
        appendLog("Created routine: \(routine.title)")
    }

    func toggleMCPConnector(_ connector: MCPConnectorProfile) {
        guard let index = mcpConnectors.firstIndex(where: { $0.id == connector.id }) else { return }
        mcpConnectors[index] = mcpConnectorService.toggle(mcpConnectors[index])
        mcpConnectorStore.save(mcpConnectors)
        mcpStatusText = mcpConnectorService.statusReport(connectors: mcpConnectors)
        refreshAgentTools()
        appendLog("MCP connector \(mcpConnectors[index].name) toggled to \(mcpConnectors[index].isEnabled ? "enabled" : "off").")
    }

    func checkMCPConnector(_ connector: MCPConnectorProfile) {
        guard let index = mcpConnectors.firstIndex(where: { $0.id == connector.id }) else { return }
        mcpConnectors[index].status = mcpConnectorService.validationStatus(for: mcpConnectors[index])
        mcpConnectorStore.save(mcpConnectors)
        mcpStatusText = mcpConnectorService.statusReport(connectors: mcpConnectors)
        refreshAgentTools()
        appendLog("Checked MCP connector \(mcpConnectors[index].name): \(mcpConnectors[index].status.rawValue).")
    }

    func toggleSocialConnector(_ connector: SocialConnectorProfile) {
        guard let index = socialConnectors.firstIndex(where: { $0.id == connector.id }) else { return }
        var copy = socialConnectors[index]
        copy.status = socialConnectorService.validationStatus(for: copy)
        guard copy.status == .connected || copy.isEnabled else {
            socialStatusText = "\(copy.displayName) needs setup before it can be enabled."
            appendLog("Social connector \(copy.displayName) needs setup.")
            return
        }
        copy.isEnabled.toggle()
        if !copy.isEnabled, copy.status == .connected {
            copy.status = .paused
        } else if copy.isEnabled {
            copy.status = .connected
        }
        socialConnectors[index] = copy
        socialConnectorStore.save(socialConnectors)
        socialStatusText = socialConnectorService.statusReport(connectors: socialConnectors)
        refreshAgentTools()
        appendLog("Social connector \(copy.displayName) toggled to \(copy.isEnabled ? "enabled" : "off").")
    }

    func updateSocialConnector(_ connector: SocialConnectorProfile, webhookURL: String, destination: String, token: String) {
        guard let index = socialConnectors.firstIndex(where: { $0.id == connector.id }) else { return }
        var copy = socialConnectors[index]
        copy.webhookURL = webhookURL.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.allowedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        if !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                try socialConnectorStore.saveSecret(token.trimmingCharacters(in: .whitespacesAndNewlines), for: copy)
                copy.botTokenSaved = true
            } catch {
                appendAssistant("I could not save the \(copy.displayName) secret: \(error.localizedDescription)", shouldSpeak: false)
            }
        }
        copy.status = socialConnectorService.validationStatus(for: copy)
        socialConnectors[index] = copy
        socialConnectorStore.save(socialConnectors)
        socialStatusText = socialConnectorService.statusReport(connectors: socialConnectors)
        refreshAgentTools()
        appendLog("Updated social connector \(copy.displayName): \(copy.status.rawValue).")
    }

    func refreshComputerControlStatus(prompt: Bool) {
        activeApplicationName = computerControl.activeApplicationName()
        let trusted = computerControl.isAccessibilityTrusted(prompt: prompt)
        computerControlStatus = trusted
            ? "Ready. Accessibility permission is enabled."
            : "Needs Accessibility permission for browser inspection, clicking, typing, and keyboard control."
        updateAdvancedComputerUseReport()
        refreshAgentTools()
        refreshVoiceDiagnostics()
    }

    func openAccessibilitySettings() {
        computerControl.openAccessibilitySettings()
        refreshComputerControlStatus(prompt: true)
    }

    func updateAdvancedComputerUseReport() {
        computerUseReport = computerControl.advancedReport()
    }

    func refreshPrivacyPermissionStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionDetail = "Ready. Microphone access is enabled."
            microphonePermissionState = .ready
        case .notDetermined:
            microphonePermissionDetail = "Not requested yet. Click Request Mic."
            microphonePermissionState = .warning
        case .denied, .restricted:
            microphonePermissionDetail = "Needs permission in System Settings > Privacy & Security > Microphone."
            microphonePermissionState = .actionNeeded
        @unknown default:
            microphonePermissionDetail = "Microphone permission status is unknown."
            microphonePermissionState = .warning
        }

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechPermissionDetail = "Ready. Speech Recognition is enabled."
            speechPermissionState = .ready
        case .notDetermined:
            speechPermissionDetail = "Not requested yet. Click Request Speech."
            speechPermissionState = .warning
        case .denied, .restricted:
            speechPermissionDetail = "Needs permission in System Settings > Privacy & Security > Speech Recognition."
            speechPermissionState = .actionNeeded
        @unknown default:
            speechPermissionDetail = "Speech Recognition permission status is unknown."
            speechPermissionState = .warning
        }

        if CGPreflightScreenCaptureAccess() {
            screenRecordingPermissionDetail = "Ready. Screen Recording is enabled."
            screenRecordingPermissionState = .ready
        } else {
            screenRecordingPermissionDetail = "Needed for Look at my screen and screenshot vision."
            screenRecordingPermissionState = .warning
        }
        refreshAgentTools()
        refreshVoiceDiagnostics()
    }

    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPrivacyPermissionStatus()
                self?.appendLog("Microphone permission requested.")
            }
        }
    }

    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] _ in
            Task { @MainActor in
                self?.refreshPrivacyPermissionStatus()
                self?.appendLog("Speech Recognition permission requested.")
            }
        }
    }

    func requestScreenRecordingPermission() {
        _ = CGRequestScreenCaptureAccess()
        refreshPrivacyPermissionStatus()
        appendLog("Screen Recording permission requested.")
    }

    func openPrivacySettings(_ pane: PrivacySettingsPane) {
        guard let url = URL(string: pane.urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = launchAtLoginService.status() == .enabled
        launchAtLoginStatus = launchAtLoginService.statusText()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginService.setEnabled(enabled)
            refreshLaunchAtLoginStatus()
            appendLog(enabled ? "Launch at login enabled." : "Launch at login disabled.")
        } catch {
            refreshLaunchAtLoginStatus()
            launchAtLoginStatus = "Could not update login startup: \(error.localizedDescription)"
            appendLog("Launch at login update failed: \(error.localizedDescription)")
        }
    }

    func appendLog(_ message: String) {
        let entry = LocalLogEntry(message: message)
        logs.insert(entry, at: 0)
        logs = Array(logs.prefix(200))
        logStore.save(logs)
    }

    private func recordTaskPlanned(_ task: AgentTask) {
        let entry = TaskHistoryEntry(
            title: task.explanation,
            userText: task.userText,
            category: task.category.rawValue,
            risk: task.riskLevel.rawValue,
            expectedResult: task.expectedResult,
            requiresConfirmation: task.requiresConfirmation,
            state: task.requiresConfirmation ? .waitingForConfirmation : .planned,
            summary: task.requiresConfirmation ? "Waiting for your confirmation." : "Planned and ready to run."
        )
        activeTaskHistoryID = entry.id
        taskHistory.insert(entry, at: 0)
        taskHistory = Array(taskHistory.prefix(100))
        taskHistoryStore.save(taskHistory)
    }

    private func updateActiveTaskHistory(state: TaskHistoryEntry.State, summary: String) {
        guard let id = activeTaskHistoryID,
              let index = taskHistory.firstIndex(where: { $0.id == id }) else { return }
        taskHistory[index].state = state
        taskHistory[index].summary = summary
        taskHistory[index].updatedAt = Date()
        taskHistoryStore.save(taskHistory)
    }

    private func diagnosticsMarkdown(summary: LaunchReadinessSummary) -> String {
        let date = Date().formatted(date: .abbreviated, time: .standard)
        let readinessRows = summary.items.map { item in
            "- [\(item.state == .ready ? "x" : " ")] \(item.category.rawValue): \(item.title) - \(redacted(item.detail))"
        }.joined(separator: "\n")

        let taskRows = taskHistory.prefix(20).map { entry in
            """
            - \(entry.updatedAt.formatted(date: .abbreviated, time: .standard)) | \(entry.state.rawValue) | \(entry.risk) | \(redacted(entry.title))
              Summary: \(redacted(entry.summary))
            """
        }.joined(separator: "\n")

        let logRows = logs.prefix(80).map { entry in
            "- \(entry.createdAt.formatted(date: .abbreviated, time: .standard)) \(redacted(entry.message))"
        }.joined(separator: "\n")

        return """
        # Earth Agent Diagnostics

        Generated: \(date)

        This report is designed for debugging. API keys and token-like strings are redacted before export.

        ## Launch Readiness

        Score: \(summary.score)%
        Status: \(summary.label)
        Detail: \(summary.detail)

        \(readinessRows)

        ## App State

        - Status: \(status.rawValue)
        - Safety mode: \(safetyMode.rawValue)
        - Provider: \(redacted(providerConfig.providerName))
        - Model: \(redacted(providerConfig.modelName))
        - Base URL: \(redacted(providerConfig.baseURL))
        - Provider test: \(redacted(providerTestStatus))
        - Voice provider: \(redacted(voiceConfig.providerName))
        - Voice model: \(redacted(voiceConfig.modelName))
        - Voice ID: \(redacted(voiceConfig.voiceID))
        - Voice test: \(redacted(voiceTestStatus))
        - Launch at login: \(launchAtLoginStatus)
        - Shortcuts: \(shortcutStatus)

        ## Permissions

        - Microphone: \(redacted(microphonePermissionDetail))
        - Speech Recognition: \(redacted(speechPermissionDetail))
        - Screen Recording: \(redacted(screenRecordingPermissionDetail))
        - Accessibility: \(redacted(computerControlStatus))
        - Active app: \(redacted(activeApplicationName))

        ## Recent Task History

        \(taskRows.isEmpty ? "No task history yet." : taskRows)

        ## Recent Logs

        \(logRows.isEmpty ? "No logs yet." : logRows)
        """
    }

    private func launchReadinessChatSummary() -> String {
        let summary = launchReadiness
        let actionNeeded = summary.items.filter { $0.state == .actionNeeded }
        let warnings = summary.items.filter { $0.state == .warning }

        let nextSteps = (actionNeeded + warnings.prefix(3)).prefix(4).map { item in
            "- \(item.title): \(item.detail)"
        }.joined(separator: "\n")

        let body = nextSteps.isEmpty
            ? "Everything in the current readiness checklist is green."
            : nextSteps

        return """
        Earth launch readiness: \(summary.score)%.

        Status: \(summary.label)
        Detail: \(summary.detail)
        Ready checks: \(summary.readyCount)/\(summary.totalCount)

        Next attention items:
        \(body)
        """
    }

    private func diagnosticsDirectoryURL() throws -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("EarthAgent Diagnostics", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func diagnosticsTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter.string(from: Date())
    }

    private func redacted(_ value: String) -> String {
        let patterns = [
            #"(?i)(api[_ -]?key|authorization|bearer|token|secret)\s*[:=]\s*[A-Za-z0-9_\-\.]{12,}"#,
            #"(?i)bearer\s+[A-Za-z0-9_\-\.]{12,}"#,
            #"[A-Za-z0-9_\-]{24,}\.[A-Za-z0-9_\-]{12,}\.[A-Za-z0-9_\-]{12,}"#,
            #"[A-Za-z0-9_\-]{48,}"#
        ]
        return patterns.reduce(value) { current, pattern in
            current.replacingOccurrences(of: pattern, with: "[redacted]", options: .regularExpression)
        }
    }

    private func normalizedModels(_ models: [String]) -> [String] {
        Array(Set(models.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func addAttachments(from urls: [URL]) {
        let newAttachments = urls.map(makeAttachment)
        pendingAttachments = normalizedAttachments(pendingAttachments + newAttachments)
        appendLog("Selected \(newAttachments.count) attachment\(newAttachments.count == 1 ? "" : "s").")
    }

    private func normalizedAttachments(_ attachments: [ChatAttachment]) -> [ChatAttachment] {
        var seen = Set<String>()
        return attachments.filter { attachment in
            let key = attachment.url.path
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
        .prefix(8)
        .map { $0 }
    }

    private func makeAttachment(from url: URL) -> ChatAttachment {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
        let type = values?.contentType ?? UTType(filenameExtension: url.pathExtension)
        let byteCount = Int64(values?.fileSize ?? 0)
        let kind = attachmentKind(for: type, url: url)
        let preview = textPreview(for: url, type: type, byteCount: byteCount)
        return ChatAttachment(
            url: url,
            name: url.lastPathComponent,
            kind: kind,
            byteCount: byteCount,
            textPreview: preview
        )
    }

    private func attachmentKind(for type: UTType?, url: URL) -> ChatAttachment.Kind {
        if type?.conforms(to: .image) == true { return .photo }
        if type?.conforms(to: .movie) == true || type?.conforms(to: .audiovisualContent) == true { return .video }
        if type?.conforms(to: .pdf) == true || type?.conforms(to: .text) == true || type?.conforms(to: .content) == true {
            return .document
        }

        let imageExtensions = ["jpg", "jpeg", "png", "heic", "webp", "gif"]
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv"]
        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext) { return .photo }
        if videoExtensions.contains(ext) { return .video }
        return .file
    }

    private func textPreview(for url: URL, type: UTType?, byteCount: Int64) -> String? {
        let isPDF = type?.conforms(to: .pdf) == true || url.pathExtension.lowercased() == "pdf"
        if isPDF {
            return pdfTextPreview(for: url, byteCount: byteCount)
        }

        guard byteCount <= 500_000 else { return nil }
        let textExtensions = ["txt", "md", "csv", "json", "xml", "html", "css", "js", "ts", "swift", "py", "rb", "yaml", "yml"]
        let looksReadable = type?.conforms(to: .text) == true || textExtensions.contains(url.pathExtension.lowercased())
        guard looksReadable, let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        return String(clean.prefix(4_000))
    }

    private func pdfTextPreview(for url: URL, byteCount: Int64) -> String? {
        guard byteCount <= 5_000_000 else { return nil }
        guard let document = PDFDocument(url: url),
              let text = document.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        return String(text.prefix(4_000))
    }

    private func attachmentPromptText(userText: String, attachments: [ChatAttachment]) -> String {
        guard !attachments.isEmpty else { return userText }
        let fileContext = attachments.map { attachment in
            var lines = [
                "- \(attachment.name)",
                "  Type: \(attachment.kind.rawValue)",
                "  Size: \(attachment.displaySize)"
            ]
            if let preview = attachment.textPreview {
                lines.append("  Text preview:\n\(preview)")
            } else if attachment.kind == .photo {
                if attachment.byteCount <= 4_000_000 {
                    lines.append("  Note: This photo is attached for vision-capable models.")
                } else {
                    lines.append("  Note: This photo is too large for inline vision, so only metadata is included.")
                }
            } else if attachment.kind == .document {
                lines.append("  Note: Document text could not be extracted in this build, so only metadata is included.")
            } else if attachment.kind == .video {
                lines.append("  Note: Video upload is attached as metadata in this build. Ask for a summary only if you provide a transcript or still frames.")
            }
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n\n")

        return """
        \(userText)

        Attached file context:
        \(fileContext)
        """
    }

    private func isStopCommand(_ lowered: String) -> Bool {
        let trimmed = lowered.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return trimmed == "stop" ||
            trimmed == "cancel" ||
            trimmed == "emergency stop" ||
            trimmed == "stop earth" ||
            trimmed == "stop agent" ||
            trimmed == "stop talking"
    }

    private func isPauseCommand(_ lowered: String) -> Bool {
        let trimmed = lowered.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return trimmed == "pause" ||
            trimmed == "pause task" ||
            trimmed == "take over" ||
            trimmed == "let me take over"
    }

    private func looksLikeSensitiveMemory(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let blockedWords = ["api key", "apikey", "password", "passcode", "secret key", "private key", "credit card", "cvv", "bank account"]
        return blockedWords.contains { lowered.contains($0) }
    }

    private func handleUserText(_ text: String, attachments: [ChatAttachment] = []) async {
        status = .thinking
        currentActivity = isConversationMode ? "Listening and preparing a spoken reply..." : "Answering..."
        let planningText = attachmentPromptText(userText: text, attachments: attachments)
        let task = planner.plan(for: planningText, safetyMode: safetyMode)
        latestPlan = task
        recordTaskPlanned(task)
        if task.action.shouldShowPlanPreview {
            appendAssistant(actionPreview(for: task), shouldSpeak: false)
        }

        if task.requiresConfirmation {
            currentActivity = nil
            pendingConfirmation = task
            status = .waitingForConfirmation
            return
        }

        await execute(task)
    }

    private func execute(_ agentTask: AgentTask) async {
        guard !Task.isCancelled else { return }
        updateActiveTaskHistory(state: .running, summary: "Running now.")
        status = .working
        activeTaskTitle = agentTask.explanation
        taskRunSteps = taskRunner.makeSteps(from: agentTask)
        let showsCursor = agentTask.action.showsAICursor
        aiCursorVisible = showsCursor
        userControlBaseline = NSEvent.mouseLocation
        userControlArmedAt = Date().addingTimeInterval(1.5)

        for (index, step) in agentTask.steps.enumerated() {
            guard !Task.isCancelled, !isTaskStopped, !isTaskPaused else { return }
            updateTaskStep(index, state: .running, detail: "Working")
            currentActivity = step
            appendLog("Step: \(step)")
            if showsCursor {
                await animateAICursor(stepIndex: index)
            }
            updateTaskStep(index, state: .completed, detail: "Done")
        }

        let requestAttachments = messages.last(where: { $0.role == .user })?.attachments ?? []

        switch agentTask.action {
        case .chatOnly:
            await askAI(agentTask.userText, attachments: requestAttachments)
        case .openApp(let name):
            do {
                try automation.openApplication(named: name)
                complete("Opened \(name).")
            } catch {
                fail("I could not open \(name): \(error.localizedDescription)")
            }
        case .openWebsite(let url):
            automation.openWebsite(url)
            complete("Opened \(url.absoluteString).")
        case .draftOnly:
            await askAI(agentTask.userText + "\n\nDraft the requested text only. Do not publish or send anything.", attachments: requestAttachments)
        case .createWebsite(let prompt):
            do {
                let result = try websiteBuilder.createWebsite(from: prompt)
                complete("Created a starter website and opened it for you.\n\nFolder:\n\(result.directory.path)\n\nMain file:\n\(result.indexFile.path)", shouldSpeak: true)
            } catch {
                fail("I could not create the website: \(error.localizedDescription)")
            }
        case .reportActiveApp:
            refreshComputerControlStatus(prompt: false)
            complete("You are currently using: \(activeApplicationName).", shouldSpeak: true)
        case .reportComputerControlStatus:
            refreshComputerControlStatus(prompt: false)
            complete("Computer control status: \(computerControlStatus)\n\nActive app: \(activeApplicationName)", shouldSpeak: true)
        case .inspectVisibleElements:
            do {
                refreshComputerControlStatus(prompt: false)
                let elements = try computerControl.inspectVisibleElements()
                visibleElements = elements
                let summary = elements.isEmpty
                    ? "I did not find useful clickable elements in \(activeApplicationName)."
                    : elements.map(\.summary).joined(separator: "\n")
                complete("Visible UI elements in \(activeApplicationName):\n\n\(summary)\n\nTo click one, say: Click element 1.", shouldSpeak: true)
            } catch {
                failComputerControl(error, fallback: "Open Safety > Accessibility to grant permission, then try again.")
            }
        case .browserSearch(let query):
            browserUse.openSearch(query: query)
            complete("Opened a browser search for: \(query)\n\nAfter the page loads, say: Inspect browser.", shouldSpeak: true)
        case .browserInspect:
            do {
                refreshComputerControlStatus(prompt: false)
                let elements = try browserUse.inspectBrowserElements()
                visibleElements = elements
                browserCandidates = browserUse.readResultCandidates(from: elements)
                let summary = browserCandidates.isEmpty
                    ? elements.map(\.summary).joined(separator: "\n")
                    : browserCandidates.map(\.summary).joined(separator: "\n")
                let fallback = summary.isEmpty ? "I could not find useful browser elements in \(activeApplicationName)." : summary
                complete("Browser results in \(activeApplicationName):\n\n\(fallback)\n\nYou can say: Open result 1, or Click element 1 after you confirm.", shouldSpeak: true)
            } catch {
                failComputerControl(error, fallback: "Open Safety > Accessibility to grant permission, then try again.")
            }
        case .openBrowserCandidate(let index, let kind):
            do {
                let candidate = try resolveBrowserCandidate(index: index, kind: kind)
                await waitForUserToFocusTarget(seconds: 2, instruction: "Focus the browser now. I will open \(candidate.title) in 2 seconds.")
                try computerControl.clickElement(index: candidate.elementID)
                complete("Opened \(candidate.title).", shouldSpeak: true)
            } catch {
                failComputerControl(error, fallback: "Run Inspect browser again, then try the command once more.")
            }
        case .clickElement(let index):
            do {
                refreshComputerControlStatus(prompt: false)
                if visibleElements.first(where: { $0.id == index }) == nil {
                    visibleElements = try computerControl.inspectVisibleElements()
                }
                let elementName = visibleElements.first { $0.id == index }?.displayName ?? "element #\(index)"
                await waitForUserToFocusTarget(seconds: 2, instruction: "Focus the target app now. I will click \(elementName) in 2 seconds.")
                try computerControl.clickElement(index: index)
                complete("Clicked \(elementName) in \(activeApplicationName).", shouldSpeak: true)
            } catch {
                failComputerControl(error, fallback: "Refresh visible elements and try again.")
            }
        case .typeText(let text):
            do {
                refreshComputerControlStatus(prompt: false)
                await waitForUserToFocusTarget(seconds: 3, instruction: "Click the target text field now. I will type in 3 seconds.")
                try computerControl.typeTextIntoFocusedField(text)
                complete("Typed into the focused field in \(activeApplicationName).", shouldSpeak: true)
            } catch {
                failComputerControl(error, fallback: "Open Safety > Accessibility to grant permission, then try again.")
            }
        case .pressShortcut(let shortcut):
            do {
                refreshComputerControlStatus(prompt: false)
                await waitForUserToFocusTarget(seconds: 2, instruction: "Focus the target app now. I will press \(shortcut) in 2 seconds.")
                try computerControl.pressShortcut(shortcut)
                complete("Pressed \(shortcut) in \(activeApplicationName).", shouldSpeak: true)
            } catch {
                failComputerControl(error, fallback: "Open Safety > Accessibility to grant permission, then try again.")
            }
        case .listRoutines:
            complete(routineReport(), shouldSpeak: true)
        case .createRoutine(let title, let prompt):
            createRoutine(title: title, prompt: prompt)
            complete("Created routine: \(title). It is off until you enable it in the Agents tab.", shouldSpeak: true)
        case .runRoutine(let id):
            await runRoutineByID(id)
        case .runSubagents(let prompt):
            await runSubagents(for: prompt)
        case .mcpStatus:
            mcpStatusText = mcpConnectorService.statusReport(connectors: mcpConnectors)
            complete(mcpStatusText, shouldSpeak: true)
        case .advancedComputerUseReport:
            updateAdvancedComputerUseReport()
            complete(computerUseReport?.summary ?? "Computer-use report is not available yet.", shouldSpeak: true)
        case .listRunningApps:
            let apps = computerControl.runningApplicationNames()
            complete(apps.isEmpty ? "I could not read the running app list." : "Running apps:\n\n" + apps.map { "- \($0)" }.joined(separator: "\n"), shouldSpeak: true)
        case .showLaunchReadiness:
            complete(launchReadinessChatSummary(), shouldSpeak: true)
        case .exportDiagnosticsReport:
            if let file = exportDiagnosticsReport() {
                complete("Exported Earth Agent diagnostics.\n\nFile:\n\(file.path)", shouldSpeak: true)
            } else {
                fail("I could not export the diagnostics report. \(diagnosticsExportStatus)")
            }
        case .openDiagnosticsFolder:
            do {
                let directory = try diagnosticsDirectoryURL()
                NSWorkspace.shared.open(directory)
                complete("Opened your Earth Agent diagnostics folder.\n\nFolder:\n\(directory.path)", shouldSpeak: true)
            } catch {
                fail("I could not open the diagnostics folder: \(error.localizedDescription)")
            }
        case .lookAtScreen(let prompt):
            do {
                let screenshot = try captureScreenAttachmentObject()
                attachToLatestUserMessage(screenshot)
                appendLog("Captured screen for command: \(screenshot.name)")
                let screenPrompt = attachmentPromptText(
                    userText: """
                    \(prompt)

                    Please use the attached screenshot as visual context. Be concise, describe the important visible details, and suggest the next safe action.
                    """,
                    attachments: [screenshot]
                )
                await askAI(screenPrompt, attachments: [screenshot])
            } catch {
                fail("I could not look at the screen: \(error.localizedDescription) You can also use the camera button or drag a screenshot into chat.")
            }
        case .summarizeClipboard(let instruction):
            do {
                let text = try clipboard.readText()
                appendLog("Read text clipboard on explicit user request.")
                await askAI("""
                \(instruction)

                The user explicitly asked Earth Agent to read the current clipboard. Summarize, explain, or transform only the clipboard text below. If it contains private or sensitive data, warn the user before suggesting sharing it.

                Clipboard text:
                \(text)
                """)
            } catch {
                fail("I could not read text from the clipboard: \(error.localizedDescription) Copy some text first, or paste it into Earth Agent.")
            }
        case .copyLastAssistantMessage:
            guard let lastReply = messages.last(where: { $0.role == .assistant })?.content
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !lastReply.isEmpty else {
                fail("I do not have an assistant reply to copy yet. Ask me something first, then say: Copy your last answer.")
                return
            }
            do {
                try clipboard.writeText(lastReply)
                appendLog("Copied latest assistant reply to clipboard on explicit user request.")
                complete("Copied my last reply to the clipboard.", shouldSpeak: true)
            } catch {
                fail("I could not copy my last reply: \(error.localizedDescription)")
            }
        case .saveLastAssistantMessage:
            guard let lastReply = messages.last(where: { $0.role == .assistant })?.content
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !lastReply.isEmpty else {
                fail("I do not have an assistant reply to save yet. Ask me something first, then say: Save your last answer.")
                return
            }
            do {
                let result = try noteWriter.save(title: "Earth Agent Answer", body: lastReply)
                appendLog("Saved latest assistant reply to note: \(result.file.path)")
                NSWorkspace.shared.open(result.directory)
                complete("Saved my last reply as a note.\n\nFile:\n\(result.file.path)", shouldSpeak: true)
            } catch {
                fail("I could not save my last reply as a note: \(error.localizedDescription)")
            }
        case .openNotesFolder:
            do {
                let directory = try noteWriter.ensureNotesDirectory()
                NSWorkspace.shared.open(directory)
                complete("Opened your Earth Agent notes folder.\n\nFolder:\n\(directory.path)", shouldSpeak: true)
            } catch {
                fail("I could not open the notes folder: \(error.localizedDescription)")
            }
        case .listNotes:
            do {
                let notes = try noteWriter.listNotes()
                recentNotes = notes
                if notes.isEmpty {
                    complete("You do not have saved Earth Agent notes yet. Say: Save your last answer as a note.", shouldSpeak: true)
                } else {
                    let rows = notes.enumerated().map { index, note in
                        "\(index + 1). \(note.title)\n   \(note.file.path)"
                    }.joined(separator: "\n\n")
                    complete("Recent Earth Agent notes:\n\n\(rows)", shouldSpeak: true)
                }
            } catch {
                fail("I could not list saved notes: \(error.localizedDescription)")
            }
        case .openNote(let index):
            do {
                let note = try resolveNote(index: index)
                NSWorkspace.shared.open(note.file)
                complete("Opened note \(note.title).\n\nFile:\n\(note.file.path)", shouldSpeak: true)
            } catch {
                fail("\(error.localizedDescription) Say: List my saved notes, then ask me to open one.")
            }
        case .readNote(let index):
            do {
                let note = try resolveNote(index: index)
                let text = try noteWriter.read(note)
                complete("Note \(note.title):\n\n\(text)", shouldSpeak: true)
            } catch {
                fail("\(error.localizedDescription) Say: List my saved notes, then ask me to read one.")
            }
        case .focusApp(let name):
            do {
                try computerControl.focusApplication(named: name)
                refreshComputerControlStatus(prompt: false)
                complete("Focused \(name).", shouldSpeak: true)
            } catch {
                fail("I could not focus \(name). Make sure the app is already open, then try again.")
            }
        case .scroll(let direction):
            do {
                refreshComputerControlStatus(prompt: false)
                try computerControl.scroll(direction: direction)
                complete("Scrolled \(direction) in \(activeApplicationName).", shouldSpeak: true)
            } catch {
                failComputerControl(error, fallback: "Open Safety > Accessibility to grant permission, then try again.")
            }
        case .needsConfirmation:
            complete("""
            I will not perform that high-risk action automatically.

            I can help draft the text, prepare a checklist, or guide you step by step, but sending, publishing, buying, deleting, submitting applications, changing accounts, or sharing private data must stay under your direct control.
            """, shouldSpeak: true)
        }
    }

    private func routineTask(for routine: AgentRoutine, requiresConfirmation: Bool) -> AgentTask {
        AgentTask(
            userText: routine.prompt,
            explanation: "Routine: \(routine.title)",
            steps: [
                "I am loading the saved routine prompt.",
                "I will run it inside Earth Agent first.",
                "External actions still require confirmation."
            ],
            action: .runRoutine(id: routine.id),
            requiresConfirmation: requiresConfirmation
        )
    }

    private func routineFromRunCommand(_ lowered: String) -> AgentRoutine? {
        guard lowered.contains("run routine") || lowered.contains("start routine") else { return nil }
        if let number = firstNumber(in: lowered), routines.indices.contains(number - 1) {
            return routines[number - 1]
        }
        return routines.first { routine in
            lowered.contains(routine.title.lowercased())
        }
    }

    private func runRoutineByID(_ id: UUID) async {
        guard let index = routines.firstIndex(where: { $0.id == id }) else {
            fail("I could not find that routine anymore.")
            return
        }

        let routine = routines[index]
        routines[index] = routineService.markRan(routine)
        routineStore.save(routines)
        routineStatus = "Ran \(routine.title)."
        appendLog("Running routine: \(routine.title)")
        await askAI("""
        Run this local Earth Agent routine.

        Routine title: \(routine.title)
        Routine prompt: \(routine.prompt)

        Important: keep this inside chat unless the user explicitly confirms an external action.
        """)
    }

    private func runSubagents(for prompt: String) async {
        do {
            let apiKey = try settingsStore.loadAPIKey()
            let configuration = providerConfig
            subagentRuns = subagentCoordinator.makeRuns(for: prompt)
            let requests = subagentRuns.enumerated().map { index, run in
                (
                    index: index,
                    systemPrompt: subagentCoordinator.systemPrompt(for: run.role),
                    userPrompt: prompt
                )
            }

            for index in subagentRuns.indices {
                guard !Task.isCancelled, !isTaskStopped else { return }
                subagentRuns[index].state = .running
                subagentRuns[index].summary = "Thinking"
                subagentRuns[index].currentTool = "AI provider"
                subagentRuns[index].events = ["Queued", "Started \(subagentRuns[index].title) review"]
                subagentRuns[index].updatedAt = Date()
            }
            currentActivity = "Agent swarm is reviewing with \(subagentRuns.count) specialists..."

            await withTaskGroup(of: (index: Int, succeeded: Bool, message: String).self) { group in
                for request in requests {
                    group.addTask {
                        do {
                            let client = OpenAICompatibleClient(configuration: configuration, apiKey: apiKey)
                            let reply = try await client.send(messages: [
                                ChatMessage(role: .system, content: request.systemPrompt),
                                ChatMessage(role: .user, content: request.userPrompt)
                            ])
                            return (request.index, true, reply)
                        } catch {
                            return (request.index, false, error.localizedDescription)
                        }
                    }
                }

                for await result in group {
                    guard !Task.isCancelled, !isTaskStopped else {
                        group.cancelAll()
                        return
                    }
                    if result.succeeded {
                        subagentRuns[result.0].state = .completed
                        subagentRuns[result.0].summary = result.message
                        subagentRuns[result.0].currentTool = nil
                        subagentRuns[result.0].events.append("Completed")
                    } else {
                        subagentRuns[result.0].state = .failed
                        subagentRuns[result.0].summary = result.message
                        subagentRuns[result.0].currentTool = nil
                        subagentRuns[result.0].events.append("Failed: \(result.message)")
                    }
                    subagentRuns[result.0].updatedAt = Date()
                    let completed = subagentRuns.filter { $0.state == .completed || $0.state == .failed }.count
                    currentActivity = "Agent swarm reviewed \(completed) of \(subagentRuns.count) specialists..."
                }
            }

            complete(subagentCoordinator.synthesize(prompt: prompt, runs: subagentRuns), shouldSpeak: true)
        } catch KeychainError.missingItem {
            fail("Agent swarm needs your AI provider key. Open Settings, save the key, then press Test.")
        } catch {
            fail(friendlyAIError(error))
        }
    }

    private func routineReport() -> String {
        guard !routines.isEmpty else {
            return "No routines yet. Say: Create routine to draft a Friday reflection."
        }

        let rows = routines.enumerated().map { index, routine in
            "\(index + 1). \(routine.title) — \(routine.schedule.rawValue), \(routine.statusText)\n   Prompt: \(routine.prompt)"
        }
        .joined(separator: "\n\n")
        return """
        Local routines:

        \(rows)

        To run one, say: Run routine 1.
        """
    }

    private func startRoutineMonitor() {
        routineMonitorTask?.cancel()
        routineMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.checkDueRoutines()
                try? await Task.sleep(nanoseconds: 60_000_000_000)
            }
        }
    }

    private func checkDueRoutines() {
        guard pendingConfirmation == nil, status == .idle else { return }
        guard let due = routineService.dueRoutines(from: routines).first,
              let index = routines.firstIndex(where: { $0.id == due.id }) else { return }

        var offered = routines[index]
        offered.nextRunAt = routineService.nextRunDate(for: offered.schedule, after: Date().addingTimeInterval(60))
        routines[index] = offered
        routineStore.save(routines)

        let task = routineTask(for: due, requiresConfirmation: true)
        pendingConfirmation = task
        status = .waitingForConfirmation
        routineStatus = "\(due.title) is ready. Confirm to run it."
        appendAssistant("Routine ready: \(due.title). Confirm when you want me to run it.", shouldSpeak: false)
        appendLog("Routine due and waiting for confirmation: \(due.title)")
    }

    private func attachToLatestUserMessage(_ attachment: ChatAttachment) {
        guard let index = messages.lastIndex(where: { $0.role == .user }) else { return }
        let message = messages[index]
        messages[index] = ChatMessage(
            id: message.id,
            role: message.role,
            content: message.content,
            createdAt: message.createdAt,
            attachments: normalizedAttachments(message.attachments + [attachment])
        )
    }

    private func askAI(_ userText: String, attachments: [ChatAttachment] = []) async {
        do {
            let apiKey = try settingsStore.loadAPIKey()
            let client = OpenAICompatibleClient(configuration: providerConfig, apiKey: apiKey)
            let memoryContext = memories.isEmpty ? "" : "\n\nUser-approved local memories:\n" + memories.map { "- \($0.text)" }.joined(separator: "\n")
            let voiceMode = isConversationMode
            let systemPrompt = voiceMode
                ? VoicePromptBuilder.systemPrompt(memoryContext: memoryContext, sessionTurns: voiceSessionTurns)
                : SystemPrompt.text + memoryContext
            let recentLimit = voiceMode ? 6 : 8
            var recentConversation = messages.suffix(recentLimit).filter { $0.role != .system }
            let explicitUserMessage: [ChatMessage]
            if let last = recentConversation.last, last.role == .user {
                let mergedAttachments = attachments.isEmpty ? last.attachments : attachments
                recentConversation[recentConversation.count - 1] = ChatMessage(
                    id: last.id,
                    role: .user,
                    content: userText,
                    createdAt: last.createdAt,
                    attachments: mergedAttachments
                )
                explicitUserMessage = []
            } else {
                explicitUserMessage = [ChatMessage(role: .user, content: userText, attachments: attachments)]
            }
            let requestMessages = [ChatMessage(role: .system, content: systemPrompt)] +
                recentConversation +
                explicitUserMessage
            let response = try await askAIStreaming(
                client: client,
                messages: requestMessages,
                speaksReply: voiceMode
            )
            completeStreamedAssistant(
                response.text,
                streamedMessageID: response.streamedMessageID,
                shouldSpeak: voiceMode
            )
        } catch KeychainError.missingItem {
            fail("Your API key is missing. Click +, open Settings, choose a provider, paste the API key, then press Save and Test.")
        } catch {
            fail(friendlyAIError(error))
        }
    }

    private struct StreamingAIResponse {
        let text: String
        let streamedMessageID: UUID?
    }

    private func askAIStreaming(
        client: OpenAICompatibleClient,
        messages requestMessages: [ChatMessage],
        speaksReply: Bool
    ) async throws -> StreamingAIResponse {
        status = .thinking
        if speaksReply {
            voiceTurnState = .processing
            voiceHint = "Thinking..."
        }
        var streamedMessageID: UUID?
        var streamedText = ""

        do {
            let text = try await client.stream(messages: requestMessages) { [weak self] token in
                await MainActor.run {
                    guard let self else { return }
                    streamedText += token
                    let visibleText = streamedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !visibleText.isEmpty else { return }
                    let isFirstVisibleToken = streamedMessageID == nil
                    if let id = streamedMessageID,
                       let index = self.messages.firstIndex(where: { $0.id == id }) {
                        let old = self.messages[index]
                        self.messages[index] = ChatMessage(
                            id: old.id,
                            role: old.role,
                            content: visibleText,
                            createdAt: old.createdAt,
                            attachments: old.attachments
                        )
                    } else {
                        let message = ChatMessage(role: .assistant, content: visibleText)
                        streamedMessageID = message.id
                        self.messages.append(message)
                    }
                    if isFirstVisibleToken {
                        self.status = .working
                        self.currentActivity = "Answering..."
                    }
                    if speaksReply {
                        self.voiceHint = "Answering..."
                    }
                }
            }
            return StreamingAIResponse(text: text, streamedMessageID: streamedMessageID)
        } catch {
            await MainActor.run {
                if let id = streamedMessageID {
                    self.messages.removeAll { $0.id == id }
                }
                if speaksReply {
                    self.voiceHint = "Streaming was not available. Using standard reply."
                }
                self.appendLog("AI streaming fallback used.")
            }
            let text = try await client.send(messages: requestMessages)
            return StreamingAIResponse(text: text, streamedMessageID: nil)
        }
    }

    private func completeStreamedAssistant(_ text: String, streamedMessageID: UUID?, shouldSpeak: Bool) {
        status = .completed
        aiCursorVisible = false
        currentActivity = nil
        markUnfinishedTaskSteps(state: .completed, detail: "Done")

        let finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let streamedMessageID,
           let index = messages.firstIndex(where: { $0.id == streamedMessageID }) {
            let old = messages[index]
            messages[index] = ChatMessage(
                id: old.id,
                role: old.role,
                content: finalText,
                createdAt: old.createdAt,
                attachments: old.attachments
            )
        } else {
            messages.append(ChatMessage(role: .assistant, content: finalText))
        }

        appendLog("Assistant: \(finalText)")
        archiveMessage(role: .assistant, text: finalText)
        if isConversationMode {
            rememberVoiceTurn(role: .assistant, text: finalText)
        }
        speakAssistantIfNeeded(finalText, shouldSpeak: shouldSpeak)
        updateActiveTaskHistory(state: .completed, summary: finalText)
        appendLog("Completed: \(finalText)")
        scheduleStatusReset(after: 4)
        drainPromptQueueSoon()
    }

    private func complete(_ text: String, shouldSpeak: Bool = false) {
        status = .completed
        aiCursorVisible = false
        currentActivity = nil
        markUnfinishedTaskSteps(state: .completed, detail: "Done")
        appendAssistant(text, shouldSpeak: shouldSpeak)
        updateActiveTaskHistory(state: .completed, summary: text)
        appendLog("Completed: \(text)")
        scheduleStatusReset(after: 4)
        drainPromptQueueSoon()
    }

    private func fail(_ text: String) {
        status = .failed
        aiCursorVisible = false
        currentActivity = nil
        markUnfinishedTaskSteps(state: .failed, detail: "Failed")
        let shouldSpeakFailure = isConversationMode
        if isConversationMode {
            isConversationMode = false
            isListening = false
            silenceTask?.cancel()
            listeningTimeoutTask?.cancel()
            speechInput.stop()
        }
        appendAssistant(text, shouldSpeak: shouldSpeakFailure)
        updateActiveTaskHistory(state: .failed, summary: text)
        appendLog("Failed: \(text)")
        scheduleStatusReset(after: 8)
        drainPromptQueueSoon()
    }

    private func failComputerControl(_ error: Error, fallback: String) {
        if isAccessibilityPermissionError(error) {
            refreshComputerControlStatus(prompt: true)
            permissionMessage = "Earth needs Accessibility permission to inspect browser results, click, type, or press keys. Enable Earth Agent in System Settings > Privacy & Security > Accessibility. If it is already enabled, turn it off/on once and reopen Earth Agent."
            fail("""
            Earth needs macOS Accessibility permission before it can control the browser.

            Do this once:
            1. Click + and open Safety.
            2. Click Grant Permission.
            3. In System Settings > Privacy & Security > Accessibility, enable Earth Agent.
            4. If Earth Agent is already there, turn it off and on once.
            5. Reopen Earth Agent, then run Inspect browser again.
            """)
            return
        }

        fail("\(error.localizedDescription) \(fallback)")
    }

    private func isAccessibilityPermissionError(_ error: Error) -> Bool {
        if let controlError = error as? ComputerControlError,
           case .accessibilityPermissionMissing = controlError {
            return true
        }
        return error.localizedDescription.localizedCaseInsensitiveContains("Accessibility permission")
    }

    private func updateTaskStep(_ index: Int, state: TaskRunStep.State, detail: String) {
        guard taskRunSteps.indices.contains(index) else { return }
        taskRunSteps[index].state = state
        taskRunSteps[index].detail = detail
    }

    private func markUnfinishedTaskSteps(state: TaskRunStep.State, detail: String) {
        taskRunSteps = taskRunSteps.map { step in
            var copy = step
            if copy.state == .pending || copy.state == .running {
                copy.state = state
                copy.detail = detail
            }
            return copy
        }
    }

    private func resolveBrowserCandidate(index: Int?, kind: String?) throws -> BrowserResultCandidate {
        if browserCandidates.isEmpty {
            let elements = try browserUse.inspectBrowserElements()
            visibleElements = elements
            browserCandidates = browserUse.readResultCandidates(from: elements)
        }

        if let index, let candidate = browserCandidates.first(where: { $0.id == index }) {
            return candidate
        }

        if let kind {
            let loweredKind = kind.lowercased()
            if let candidate = browserCandidates.first(where: {
                $0.kind.rawValue.lowercased().contains(loweredKind) ||
                    $0.title.lowercased().contains(loweredKind)
            }) {
                return candidate
            }
        }

        if let candidate = browserCandidates.first {
            return candidate
        }

        throw NSError(
            domain: "EarthAgent.BrowserCandidate",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "I could not find a labeled browser result yet."]
        )
    }

    private func resolveNote(index: Int?) throws -> SavedNoteSummary {
        if recentNotes.isEmpty {
            recentNotes = try noteWriter.listNotes()
        }
        guard !recentNotes.isEmpty else {
            throw NSError(
                domain: "EarthAgent.Notes",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "There are no saved Earth Agent notes yet."]
            )
        }
        let requestedIndex = (index ?? 1) - 1
        guard recentNotes.indices.contains(requestedIndex) else {
            throw NSError(
                domain: "EarthAgent.Notes",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "I could not find note #\(index ?? 1)."]
            )
        }
        return recentNotes[requestedIndex]
    }

    private func appendAssistant(_ text: String, shouldSpeak: Bool = true) {
        messages.append(ChatMessage(role: .assistant, content: text))
        archiveMessage(role: .assistant, text: text)
        appendLog("Assistant: \(text)")
        if isConversationMode {
            rememberVoiceTurn(role: .assistant, text: text)
        }
        speakAssistantIfNeeded(text, shouldSpeak: shouldSpeak)
    }

    private func speakAssistantIfNeeded(_ text: String, shouldSpeak: Bool) {
        guard shouldSpeak, isConversationMode else { return }
        let speechGeneration = beginSpeechSession(
            text: text,
            hint: "Speaking. Tap mic or waveform to interrupt."
        )
        let voiceAPIKey = try? voiceSettingsStore.loadAPIKey()
        speechOutput.speak(
            spokenSummary(for: text),
            configuration: voiceConfig,
            rate: Float(voiceTurnSettings.macSpeechRate),
            apiKey: voiceAPIKey,
            onFallback: { [weak self] message in
                Task { @MainActor in
                    self?.voiceTestStatus = message
                    self?.appendLog("Voice fallback used.")
                }
            }
        ) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                guard self.isSpeaking else { return }
                self.finishSpeechSession(generation: speechGeneration, allowResumeListening: true)
            }
        }
    }

    private func spokenSummary(for text: String) -> String {
        SpokenTextCleaner.clean(text)
    }

    private func rememberVoiceTurn(role: ConversationTurn.Role, text: String, wasInterrupted: Bool = false) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        voiceSessionTurns.append(ConversationTurn(role: role, text: clean, wasInterrupted: wasInterrupted))
        if voiceSessionTurns.count > 16 {
            voiceSessionTurns.removeFirst(voiceSessionTurns.count - 16)
        }
    }

    private func stopSpeaking() {
        let wasSpeaking = isSpeaking
        invalidateSpeechSession()
        isSpeaking = false
        if wasSpeaking {
            voiceTurnState = .interrupted
            voiceHint = "Interrupted. Listening when you start again."
            rememberVoiceTurn(role: .assistant, text: "Assistant speech was interrupted by the user.", wasInterrupted: true)
        }
        speechOutput.stop()
    }

    private func beginSpeechSession(text: String, hint: String) -> Int {
        invalidateSpeechSession()
        speechSessionGeneration += 1
        isSpeaking = true
        voiceTurnState = .speaking
        voiceHint = hint
        scheduleSpeechWatchdog(for: speechSessionGeneration, text: text)
        return speechSessionGeneration
    }

    private func invalidateSpeechSession() {
        speechSessionGeneration += 1
        speechWatchdogTask?.cancel()
        speechWatchdogTask = nil
    }

    private func scheduleSpeechWatchdog(for generation: Int, text: String) {
        speechWatchdogTask?.cancel()
        let timeout = estimatedSpeechWatchdogTimeout(for: text)
        speechWatchdogTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            await MainActor.run {
                guard let self, self.speechSessionGeneration == generation, self.isSpeaking else { return }
                self.appendLog("Speech watchdog closed a stale voice session.")
                self.finishSpeechSession(generation: generation, allowResumeListening: self.isConversationMode)
            }
        }
    }

    private func estimatedSpeechWatchdogTimeout(for text: String) -> TimeInterval {
        let cleaned = spokenSummary(for: text)
        let characterEstimate = Double(cleaned.count) / 11.0
        return min(max(10, characterEstimate + 8), 75)
    }

    private func finishSpeechSession(generation: Int, allowResumeListening: Bool) {
        guard speechSessionGeneration == generation else { return }
        speechWatchdogTask?.cancel()
        speechWatchdogTask = nil
        isSpeaking = false
        voiceTurnState = .idle
        voiceHint = isConversationMode ? "Ready for your reply." : "Voice ready."
        guard allowResumeListening, isConversationMode, !isTaskStopped, !isListening else { return }
        let delay = UInt64(voiceTurnSettings.restartListeningDelay * 1_000_000_000)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            await MainActor.run {
                guard let self, self.speechSessionGeneration == generation else { return }
                guard self.isConversationMode, !self.isListening, !self.isSpeaking else { return }
                self.typedMessage = ""
                self.startListening()
            }
        }
    }

    private func handleListeningFailure(_ message: String) {
        listeningSessionGeneration += 1
        speechInput.stop()
        isListening = false
        isSpeaking = false
        silenceTask?.cancel()
        silenceTask = nil
        listeningTimeoutTask?.cancel()
        listeningTimeoutTask = nil
        if isConversationMode {
            isConversationMode = false
        }
        refreshPrivacyPermissionStatus()
        status = .failed
        voiceTurnState = .failed
        voiceHint = message
        appendAssistant("Voice input is not ready yet: \(message)", shouldSpeak: false)
        appendLog("Voice listening failed: \(message)")
    }

    private func permissionGuidance(for authorization: SpeechInputService.AuthorizationSnapshot) -> String {
        if [.denied, .restricted].contains(authorization.speechStatus) {
            return "Speech recognition permission is off. Open System Settings > Privacy & Security > Speech Recognition and enable Earth Agent."
        }
        if [.denied, .restricted].contains(authorization.microphoneStatus) {
            return "Microphone permission is off. Open System Settings > Privacy & Security > Microphone and enable Earth Agent."
        }
        return "Voice input is unavailable right now."
    }

    private func scheduleStatusReset(after seconds: TimeInterval) {
        statusResetTask?.cancel()
        statusResetTask = Task { [weak self] in
            let delay = UInt64(seconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            await MainActor.run {
                guard let self, !self.isListening, !self.isSpeaking, self.pendingConfirmation == nil else { return }
                if self.status == .completed || self.status == .failed || self.status == .stopped {
                    self.status = .idle
                }
            }
        }
    }

    private func actionPreview(for task: AgentTask) -> String {
        let numberedSteps = task.steps.enumerated().map { index, step in
            "\(index + 1). \(step)"
        }.joined(separator: "\n")
        let metadata = """
        
        Intent: \(task.category.rawValue)
        Risk: \(task.riskLevel.rawValue) - \(task.riskLevel.shortDescription)
        Tools: \(task.requiredTools.joined(separator: ", "))
        Expected result: \(task.expectedResult)
        Fallback: \(task.fallback)
        """
        if task.requiresConfirmation {
            return "\(task.explanation)\n\(metadata)\n\nBefore I do it, please confirm:\n\(numberedSteps)"
        }
        return "\(task.explanation)\n\(metadata)\n\nPlan:\n\(numberedSteps)"
    }

    private func friendlyAIError(_ error: Error) -> String {
        let message = error.localizedDescription
        if message.localizedCaseInsensitiveContains("401") || message.localizedCaseInsensitiveContains("unauthorized") {
            return "The provider rejected the API key. Open Settings, paste a fresh key, then press Save and Test."
        }
        if message.localizedCaseInsensitiveContains("404") || message.localizedCaseInsensitiveContains("model") {
            return "The selected model may not be available for this provider. Open Settings, press Models, then choose a model from the dropdown."
        }
        if message.localizedCaseInsensitiveContains("base url") || message.localizedCaseInsensitiveContains("invalid") {
            return "The provider URL or response looks wrong. Open Settings and check the Base URL, then press Test."
        }
        return "I could not reach the AI provider: \(message). Open Settings and press Test Connection."
    }

    private func scheduleConversationAutoSend(isFinal: Bool) {
        let text = typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard text != lastConversationSubmittedText else { return }
        guard text.split(separator: " ").count >= voiceTurnSettings.minimumWordCount || isFinal else { return }
        silenceTask?.cancel()
        conversationSendGeneration += 1
        let generation = conversationSendGeneration
        let scheduledText = text
        silenceTask = Task { [weak self] in
            let seconds = isFinal ? self?.voiceTurnSettings.finalTranscriptDelay : self?.voiceTurnSettings.silenceDelay
            let delay = UInt64((seconds ?? 1.1) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            await MainActor.run {
                guard let self, self.isConversationMode, self.isListening else { return }
                let latest = self.typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                guard self.conversationSendGeneration == generation else { return }
                guard latest == scheduledText else { return }
                guard !latest.isEmpty, latest != self.lastConversationSubmittedText else { return }
                self.lastConversationSubmittedText = latest
                self.stopListeningAndSend()
            }
        }
    }

    private func scheduleListeningTimeoutIfNeeded() {
        listeningTimeoutTask?.cancel()
        guard isConversationMode else { return }
        let seconds = voiceTurnSettings.maximumListeningDuration
        listeningTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            await MainActor.run {
                guard let self, self.isConversationMode, self.isListening else { return }
                let text = self.typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                if text.isEmpty {
                    self.voiceHint = "Still here. Start talking when you are ready."
                    self.scheduleListeningTimeoutIfNeeded()
                } else {
                    self.lastConversationSubmittedText = text
                    self.stopListeningAndSend()
                }
            }
        }
    }

    private func waitForUserToFocusTarget(seconds: Int, instruction: String) async {
        currentActivity = instruction
        for remaining in stride(from: seconds, through: 1, by: -1) {
            guard !Task.isCancelled, !isTaskStopped, !isTaskPaused else { return }
            currentActivity = "\(instruction.replacingOccurrences(of: "in \(seconds) seconds", with: "in \(remaining) seconds"))"
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        refreshComputerControlStatus(prompt: false)
    }

    private func animateAICursor(stepIndex: Int) async {
        let mouse = NSEvent.mouseLocation
        if aiCursorPosition == .zero {
            aiCursorPosition = CGPoint(x: mouse.x + 24, y: mouse.y - 24)
        }
        let targets = [
            CGPoint(x: mouse.x + 90, y: mouse.y - 40),
            CGPoint(x: mouse.x + 150, y: mouse.y + 30),
            CGPoint(x: mouse.x + 60, y: mouse.y + 90)
        ]
        let target = targets[stepIndex % targets.count]
        let start = aiCursorPosition
        for frame in 0...24 {
            guard !Task.isCancelled, !isTaskStopped, !isTaskPaused else { return }
            let progress = CGFloat(frame) / 24.0
            aiCursorPosition = CGPoint(
                x: start.x + (target.x - start.x) * progress,
                y: start.y + (target.y - start.y) * progress
            )
            try? await Task.sleep(nanoseconds: 12_000_000)
        }
    }

    private func firstNumber(in text: String) -> Int? {
        text
            .split { !$0.isNumber }
            .compactMap { Int($0) }
            .first
    }
}

private extension AgentTask.Action {
    var shouldShowPlanPreview: Bool {
        switch self {
        case .chatOnly, .draftOnly:
            return false
        default:
            return true
        }
    }

    var showsAICursor: Bool {
        switch self {
        case .openApp, .openWebsite, .createWebsite, .browserSearch, .openBrowserCandidate, .clickElement, .typeText, .pressShortcut, .focusApp, .scroll, .saveLastAssistantMessage, .openNotesFolder, .openNote:
            return true
        case .chatOnly, .draftOnly, .reportActiveApp, .reportComputerControlStatus, .inspectVisibleElements, .browserInspect, .listRoutines, .runRoutine, .createRoutine, .runSubagents, .mcpStatus, .advancedComputerUseReport, .listRunningApps, .showLaunchReadiness, .exportDiagnosticsReport, .openDiagnosticsFolder, .lookAtScreen, .summarizeClipboard, .copyLastAssistantMessage, .listNotes, .readNote, .needsConfirmation:
            return false
        }
    }
}

enum SystemPrompt {
    static let text = """
    You are Earth Agent, a voice-first macOS desktop assistant. Be concise, conversational, and safe.
    Explain your steps in simple language. Never claim to have posted, purchased, deleted, sent, or changed accounts unless the app explicitly confirmed that action happened.
    Ask for confirmation before sensitive external actions.
    """
}
