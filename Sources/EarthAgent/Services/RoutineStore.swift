import Foundation

final class RoutineStore {
    private let defaultsKey = "earth-agent-routines-v1"

    func load() -> [AgentRoutine] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([AgentRoutine].self, from: data) else {
            return Self.defaultRoutines()
        }
        return decoded.isEmpty ? Self.defaultRoutines() : decoded
    }

    func save(_ routines: [AgentRoutine]) {
        guard let data = try? JSONEncoder().encode(routines) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    static func defaultRoutines() -> [AgentRoutine] {
        let service = RoutineService()
        return [
            service.withNextRun(
                AgentRoutine(
                    title: "Morning brief",
                    prompt: "Summarize my top priorities and suggest the next three useful actions.",
                    schedule: .dailyMorning,
                    isEnabled: false
                )
            ),
            service.withNextRun(
                AgentRoutine(
                    title: "Friday reflection draft",
                    prompt: "Draft a concise weekly reflection about what I learned and what to improve next. Do not publish it.",
                    schedule: .fridayMorning,
                    isEnabled: false
                )
            ),
            service.withNextRun(
                AgentRoutine(
                    title: "Project improvement",
                    prompt: "Review my current project plan and suggest one small improvement I can make today.",
                    schedule: .manual,
                    isEnabled: false
                )
            )
        ]
    }
}

final class RoutineService {
    func withNextRun(_ routine: AgentRoutine, after date: Date = Date()) -> AgentRoutine {
        var copy = routine
        copy.nextRunAt = nextRunDate(for: routine.schedule, after: date)
        return copy
    }

    func markRan(_ routine: AgentRoutine, at date: Date = Date()) -> AgentRoutine {
        var copy = routine
        copy.lastRunAt = date
        copy.nextRunAt = nextRunDate(for: routine.schedule, after: date)
        return copy
    }

    func dueRoutines(from routines: [AgentRoutine], now: Date = Date()) -> [AgentRoutine] {
        routines.filter { routine in
            routine.isEnabled &&
                routine.schedule != .manual &&
                (routine.nextRunAt ?? .distantFuture) <= now
        }
    }

    func nextRunDate(for schedule: AgentRoutine.Schedule, after date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        switch schedule {
        case .manual:
            return nil
        case .dailyMorning:
            return nextDate(hour: 9, minute: 0, after: date, calendar: calendar)
        case .dailyEvening:
            return nextDate(hour: 18, minute: 0, after: date, calendar: calendar)
        case .fridayMorning:
            var components = DateComponents()
            components.weekday = 6
            components.hour = 9
            components.minute = 0
            return calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime)
        }
    }

    private func nextDate(hour: Int, minute: Int, after date: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0

        if let today = calendar.date(from: components), today > date {
            return today
        }
        return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components) ?? date)
    }
}
