import Foundation

struct AgentRoutine: Identifiable, Codable, Equatable {
    enum Schedule: String, CaseIterable, Codable, Equatable {
        case manual = "Manual"
        case dailyMorning = "Daily morning"
        case dailyEvening = "Daily evening"
        case fridayMorning = "Friday morning"

        var detail: String {
            switch self {
            case .manual:
                return "Runs only when you press Run."
            case .dailyMorning:
                return "Checks once each morning at 9:00."
            case .dailyEvening:
                return "Checks once each evening at 18:00."
            case .fridayMorning:
                return "Checks every Friday at 9:00."
            }
        }
    }

    var id: UUID
    var title: String
    var prompt: String
    var schedule: Schedule
    var isEnabled: Bool
    var requiresConfirmation: Bool
    var createdAt: Date
    var lastRunAt: Date?
    var nextRunAt: Date?
    var pinnedProviderName: String
    var pinnedModelName: String
    var attachedSkillID: String?
    var toolset: String

    init(
        id: UUID = UUID(),
        title: String,
        prompt: String,
        schedule: Schedule,
        isEnabled: Bool = false,
        requiresConfirmation: Bool = true,
        createdAt: Date = Date(),
        lastRunAt: Date? = nil,
        nextRunAt: Date? = nil,
        pinnedProviderName: String = "Current provider",
        pinnedModelName: String = "Current model",
        attachedSkillID: String? = nil,
        toolset: String = "Core"
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.requiresConfirmation = requiresConfirmation
        self.createdAt = createdAt
        self.lastRunAt = lastRunAt
        self.nextRunAt = nextRunAt
        self.pinnedProviderName = pinnedProviderName
        self.pinnedModelName = pinnedModelName
        self.attachedSkillID = attachedSkillID
        self.toolset = toolset
    }

    var statusText: String {
        guard isEnabled else { return "Off" }
        guard let nextRunAt else { return schedule == .manual ? "Manual" : "Ready" }
        return "Next \(nextRunAt.formatted(date: .abbreviated, time: .shortened))"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case prompt
        case schedule
        case isEnabled
        case requiresConfirmation
        case createdAt
        case lastRunAt
        case nextRunAt
        case pinnedProviderName
        case pinnedModelName
        case attachedSkillID
        case toolset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        prompt = try container.decode(String.self, forKey: .prompt)
        schedule = try container.decodeIfPresent(Schedule.self, forKey: .schedule) ?? .manual
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        requiresConfirmation = try container.decodeIfPresent(Bool.self, forKey: .requiresConfirmation) ?? true
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        lastRunAt = try container.decodeIfPresent(Date.self, forKey: .lastRunAt)
        nextRunAt = try container.decodeIfPresent(Date.self, forKey: .nextRunAt)
        pinnedProviderName = try container.decodeIfPresent(String.self, forKey: .pinnedProviderName) ?? "Current provider"
        pinnedModelName = try container.decodeIfPresent(String.self, forKey: .pinnedModelName) ?? "Current model"
        attachedSkillID = try container.decodeIfPresent(String.self, forKey: .attachedSkillID)
        toolset = try container.decodeIfPresent(String.self, forKey: .toolset) ?? "Core"
    }
}
