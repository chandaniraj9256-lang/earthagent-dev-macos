import Foundation

@MainActor
final class AppServices {
    let model: AppModel

    init() {
        let keychain = KeychainService()
        let settingsStore = ProviderSettingsStore(keychain: keychain)
        let voiceSettingsStore = VoiceSettingsStore(keychain: keychain)
        let speechInput = SpeechInputService()
        let speechOutput = SpeechOutputService()
        let automation = AutomationService()
        let planner = AgentPlanner()
        let logStore = LogStore()
        let taskHistoryStore = TaskHistoryStore()
        let launchAtLoginService = LaunchAtLoginService()
        let modelDiscovery = ModelDiscoveryService()
        let memoryStore = MemoryStore()
        let websiteBuilder = WebsiteBuilderService()
        let computerControl = ComputerControlService()
        let taskRunner = TaskRunnerService()
        let browserUse = BrowserUseService(automation: automation, computerControl: computerControl)
        let clipboard = ClipboardService()
        let noteWriter = NoteWriterService()
        let routineStore = RoutineStore()
        let routineService = RoutineService()
        let subagentCoordinator = SubagentCoordinator()
        let mcpConnectorStore = MCPConnectorStore()
        let mcpConnectorService = MCPConnectorService()
        let promptQueueStore = PromptQueueStore()
        let skillStore = EarthSkillStore()
        let skillMatcher = EarthSkillMatcher()
        let sessionArchiveStore = SessionArchiveStore()
        let socialConnectorStore = SocialConnectorStore(keychain: keychain)
        let socialConnectorService = SocialConnectorService()

        self.model = AppModel(
            settingsStore: settingsStore,
            voiceSettingsStore: voiceSettingsStore,
            speechInput: speechInput,
            speechOutput: speechOutput,
            automation: automation,
            planner: planner,
            logStore: logStore,
            taskHistoryStore: taskHistoryStore,
            launchAtLoginService: launchAtLoginService,
            modelDiscovery: modelDiscovery,
            memoryStore: memoryStore,
            websiteBuilder: websiteBuilder,
            computerControl: computerControl,
            taskRunner: taskRunner,
            browserUse: browserUse,
            clipboard: clipboard,
            noteWriter: noteWriter,
            routineStore: routineStore,
            routineService: routineService,
            subagentCoordinator: subagentCoordinator,
            mcpConnectorStore: mcpConnectorStore,
            mcpConnectorService: mcpConnectorService,
            promptQueueStore: promptQueueStore,
            skillStore: skillStore,
            skillMatcher: skillMatcher,
            sessionArchiveStore: sessionArchiveStore,
            socialConnectorStore: socialConnectorStore,
            socialConnectorService: socialConnectorService
        )
    }
}
