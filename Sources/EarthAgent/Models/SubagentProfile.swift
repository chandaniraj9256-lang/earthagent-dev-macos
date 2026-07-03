import Foundation

enum SubagentRole: String, CaseIterable, Codable, Equatable, Identifiable {
    case researcher = "Researcher"
    case operatorAgent = "Operator"
    case writer = "Writer"
    case safetyReviewer = "Safety"
    case planner = "Planner"
    case decomposer = "Task Decomposer"
    case privacyGuardian = "Privacy Guardian"
    case securityAnalyst = "Security Analyst"
    case uxReviewer = "UX Reviewer"
    case macOSSpecialist = "macOS Specialist"
    case browserSpecialist = "Browser Specialist"
    case voiceDesigner = "Voice Designer"
    case providerSpecialist = "Provider Specialist"
    case memoryCurator = "Memory Curator"
    case automationDesigner = "Automation Designer"
    case qaTester = "QA Tester"
    case performanceOptimizer = "Performance Optimizer"
    case productStrategist = "Product Strategist"
    case launchAdvisor = "Launch Advisor"
    case growthMarketer = "Growth Marketer"
    case copywriter = "Copywriter"
    case visualDesigner = "Visual Designer"
    case codeReviewer = "Code Reviewer"
    case dataAnalyst = "Data Analyst"
    case fileManager = "File Manager"
    case accessibilityGuide = "Accessibility Guide"
    case confirmationOfficer = "Confirmation Officer"
    case troubleshootingAgent = "Troubleshooter"
    case integrationArchitect = "Integration Architect"
    case synthesisLead = "Synthesis Lead"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .researcher: return "magnifyingglass"
        case .operatorAgent: return "cursorarrow.motionlines"
        case .writer: return "text.bubble"
        case .safetyReviewer: return "shield.lefthalf.filled"
        case .planner: return "list.bullet.clipboard"
        case .decomposer: return "square.stack.3d.down.right"
        case .privacyGuardian: return "lock.shield"
        case .securityAnalyst: return "lock.trianglebadge.exclamationmark"
        case .uxReviewer: return "rectangle.and.hand.point.up.left"
        case .macOSSpecialist: return "desktopcomputer"
        case .browserSpecialist: return "safari"
        case .voiceDesigner: return "waveform"
        case .providerSpecialist: return "server.rack"
        case .memoryCurator: return "brain.head.profile"
        case .automationDesigner: return "gearshape.2"
        case .qaTester: return "checkmark.seal"
        case .performanceOptimizer: return "speedometer"
        case .productStrategist: return "scope"
        case .launchAdvisor: return "paperplane"
        case .growthMarketer: return "chart.line.uptrend.xyaxis"
        case .copywriter: return "pencil.and.outline"
        case .visualDesigner: return "paintpalette"
        case .codeReviewer: return "chevron.left.forwardslash.chevron.right"
        case .dataAnalyst: return "chart.bar.xaxis"
        case .fileManager: return "folder"
        case .accessibilityGuide: return "accessibility"
        case .confirmationOfficer: return "hand.raised"
        case .troubleshootingAgent: return "wrench.and.screwdriver"
        case .integrationArchitect: return "point.3.connected.trianglepath.dotted"
        case .synthesisLead: return "arrow.triangle.merge"
        }
    }
}

struct SubagentProfile: Identifiable, Codable, Equatable {
    let id: SubagentRole
    let title: String
    let purpose: String
    let instruction: String

    static let defaults: [SubagentProfile] = [
        SubagentProfile(
            id: .researcher,
            title: "Researcher",
            purpose: "Finds facts, sources, options, and missing context.",
            instruction: "You are Earth Agent's research subagent. Find the useful facts, assumptions, and options. Be concise and practical."
        ),
        SubagentProfile(
            id: .operatorAgent,
            title: "Operator",
            purpose: "Turns a request into concrete macOS/browser steps.",
            instruction: "You are Earth Agent's macOS operator subagent. Break the task into safe app/browser actions. Flag where confirmation is needed."
        ),
        SubagentProfile(
            id: .writer,
            title: "Writer",
            purpose: "Drafts user-facing text, posts, messages, and summaries.",
            instruction: "You are Earth Agent's writing subagent. Produce polished, simple text the user can edit. Do not claim anything was sent or posted."
        ),
        SubagentProfile(
            id: .safetyReviewer,
            title: "Safety",
            purpose: "Checks privacy, risk, permissions, and confirmation needs.",
            instruction: "You are Earth Agent's safety reviewer. Identify privacy risks, irreversible actions, permission needs, and final confirmations."
        ),
        SubagentProfile(
            id: .planner,
            title: "Planner",
            purpose: "Builds the shortest reliable plan for a complex request.",
            instruction: "You are Earth Agent's planning subagent. Convert the request into a clear goal, milestones, dependencies, and a minimal next action."
        ),
        SubagentProfile(
            id: .decomposer,
            title: "Task Decomposer",
            purpose: "Splits long tasks into parallel workstreams.",
            instruction: "You are Earth Agent's task decomposition subagent. Break large work into independent subtasks that specialist agents can handle in parallel."
        ),
        SubagentProfile(
            id: .privacyGuardian,
            title: "Privacy Guardian",
            purpose: "Finds personal data and identity exposure before launch.",
            instruction: "You are Earth Agent's privacy subagent. Detect personal identity, secrets, account names, private files, and public exposure risks."
        ),
        SubagentProfile(
            id: .securityAnalyst,
            title: "Security Analyst",
            purpose: "Reviews security risks, permissions, and abuse paths.",
            instruction: "You are Earth Agent's security subagent. Identify security issues, permission risks, unsafe automation, and hardening steps."
        ),
        SubagentProfile(
            id: .uxReviewer,
            title: "UX Reviewer",
            purpose: "Checks whether the product feels clear, modern, and calm.",
            instruction: "You are Earth Agent's UX reviewer. Improve clarity, flow, visual hierarchy, labels, empty states, and user confidence."
        ),
        SubagentProfile(
            id: .macOSSpecialist,
            title: "macOS Specialist",
            purpose: "Reviews Mac app behavior, permissions, packaging, and launch.",
            instruction: "You are Earth Agent's macOS specialist. Focus on SwiftUI, permissions, app installation, Keychain, speech, Accessibility, and app lifecycle."
        ),
        SubagentProfile(
            id: .browserSpecialist,
            title: "Browser Specialist",
            purpose: "Plans safe browser and website actions.",
            instruction: "You are Earth Agent's browser subagent. Plan safe website navigation, form handling, downloads, and external action confirmation."
        ),
        SubagentProfile(
            id: .voiceDesigner,
            title: "Voice Designer",
            purpose: "Improves live talk, interruption, timing, and spoken style.",
            instruction: "You are Earth Agent's voice experience subagent. Improve speech timing, turn taking, interruption, short spoken answers, and natural conversation."
        ),
        SubagentProfile(
            id: .providerSpecialist,
            title: "Provider Specialist",
            purpose: "Handles AI provider setup, model choice, and API failures.",
            instruction: "You are Earth Agent's provider subagent. Review model/provider compatibility, API key handling, fallback behavior, and error messages."
        ),
        SubagentProfile(
            id: .memoryCurator,
            title: "Memory Curator",
            purpose: "Decides what should and should not be remembered.",
            instruction: "You are Earth Agent's memory subagent. Recommend what may be remembered only with permission, what should stay temporary, and deletion controls."
        ),
        SubagentProfile(
            id: .automationDesigner,
            title: "Automation Designer",
            purpose: "Designs safe computer-control workflows.",
            instruction: "You are Earth Agent's automation subagent. Convert goals into safe, confirmable computer actions with pause, stop, and takeover points."
        ),
        SubagentProfile(
            id: .qaTester,
            title: "QA Tester",
            purpose: "Finds likely bugs, missing states, and test gaps.",
            instruction: "You are Earth Agent's QA subagent. Identify edge cases, broken states, missing tests, and verification steps."
        ),
        SubagentProfile(
            id: .performanceOptimizer,
            title: "Performance Optimizer",
            purpose: "Reduces slow responses and UI jank.",
            instruction: "You are Earth Agent's performance subagent. Look for slow AI calls, blocking UI, animation jank, heavy work, and faster response paths."
        ),
        SubagentProfile(
            id: .productStrategist,
            title: "Product Strategist",
            purpose: "Connects features to customer value and prioritization.",
            instruction: "You are Earth Agent's product strategy subagent. Explain user value, launch priority, MVP scope, and what makes the product worth paying for."
        ),
        SubagentProfile(
            id: .launchAdvisor,
            title: "Launch Advisor",
            purpose: "Checks public beta readiness and release risks.",
            instruction: "You are Earth Agent's launch subagent. Review distribution, onboarding, support, privacy, pricing, beta risks, and release blockers."
        ),
        SubagentProfile(
            id: .growthMarketer,
            title: "Growth Marketer",
            purpose: "Finds positioning, audience, and acquisition angles.",
            instruction: "You are Earth Agent's growth subagent. Suggest positioning, target user segments, landing-page claims, launch channels, and ethical growth loops."
        ),
        SubagentProfile(
            id: .copywriter,
            title: "Copywriter",
            purpose: "Writes clear launch, website, and in-app copy.",
            instruction: "You are Earth Agent's copywriting subagent. Produce concise, trustworthy, non-hype copy that a normal Mac user understands."
        ),
        SubagentProfile(
            id: .visualDesigner,
            title: "Visual Designer",
            purpose: "Improves premium visual quality and motion.",
            instruction: "You are Earth Agent's visual design subagent. Improve layout, hierarchy, motion, color balance, spacing, and premium Mac feel."
        ),
        SubagentProfile(
            id: .codeReviewer,
            title: "Code Reviewer",
            purpose: "Reviews implementation quality and maintainability.",
            instruction: "You are Earth Agent's code review subagent. Find correctness issues, maintainability risks, and focused code improvements."
        ),
        SubagentProfile(
            id: .dataAnalyst,
            title: "Data Analyst",
            purpose: "Structures metrics, evidence, and experiment decisions.",
            instruction: "You are Earth Agent's data subagent. Define useful metrics, success criteria, evidence needs, and experiment tracking."
        ),
        SubagentProfile(
            id: .fileManager,
            title: "File Manager",
            purpose: "Plans safe local file handling and exports.",
            instruction: "You are Earth Agent's file-management subagent. Handle local files, downloads, uploads, notes, exports, and deletion safeguards."
        ),
        SubagentProfile(
            id: .accessibilityGuide,
            title: "Accessibility Guide",
            purpose: "Reviews permission prompts and accessible UI.",
            instruction: "You are Earth Agent's accessibility subagent. Improve accessible labels, keyboard flow, permission explanations, and safe Accessibility API usage."
        ),
        SubagentProfile(
            id: .confirmationOfficer,
            title: "Confirmation Officer",
            purpose: "Defines when user approval is required.",
            instruction: "You are Earth Agent's confirmation subagent. Mark every step that needs approval, especially posting, sending, buying, deleting, account changes, and private data sharing."
        ),
        SubagentProfile(
            id: .troubleshootingAgent,
            title: "Troubleshooter",
            purpose: "Diagnoses user-facing failures and recovery steps.",
            instruction: "You are Earth Agent's troubleshooting subagent. Explain likely causes, fastest fixes, and user-friendly recovery steps."
        ),
        SubagentProfile(
            id: .integrationArchitect,
            title: "Integration Architect",
            purpose: "Plans MCP, APIs, providers, and tool integrations.",
            instruction: "You are Earth Agent's integration subagent. Design modular MCP connectors, API adapters, provider setup, and future tool boundaries."
        ),
        SubagentProfile(
            id: .synthesisLead,
            title: "Synthesis Lead",
            purpose: "Combines specialist outputs into one decision.",
            instruction: "You are Earth Agent's synthesis subagent. Merge conflicting briefs, remove duplication, and produce the clearest next action."
        )
    ]
}

struct SubagentRun: Identifiable, Codable, Equatable {
    enum State: String, Codable, Equatable {
        case pending = "Pending"
        case running = "Running"
        case completed = "Done"
        case failed = "Failed"
    }

    var id: UUID
    var role: SubagentRole
    var title: String
    var prompt: String
    var state: State
    var summary: String
    var currentTool: String?
    var events: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        role: SubagentRole,
        title: String,
        prompt: String,
        state: State = .pending,
        summary: String = "Waiting",
        currentTool: String? = nil,
        events: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.title = title
        self.prompt = prompt
        self.state = state
        self.summary = summary
        self.currentTool = currentTool
        self.events = events
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
