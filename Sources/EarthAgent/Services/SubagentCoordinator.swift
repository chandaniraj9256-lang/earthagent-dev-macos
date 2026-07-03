import Foundation

final class SubagentCoordinator {
    let profiles: [SubagentProfile] = SubagentProfile.defaults

    func makeRuns(for prompt: String, roles: [SubagentRole]? = nil) -> [SubagentRun] {
        let selectedRoles = roles ?? selectedRoles(for: prompt)
        let selected = profiles.filter { profile in
            selectedRoles.contains(profile.id)
        }
        return selected.map {
            SubagentRun(role: $0.id, title: $0.title, prompt: prompt)
        }
    }

    func profile(for role: SubagentRole) -> SubagentProfile {
        profiles.first { $0.id == role } ?? profiles[0]
    }

    func systemPrompt(for role: SubagentRole) -> String {
        profile(for: role).instruction + "\nReturn one compact section with concrete bullets. Do not invent completed actions."
    }

    func synthesize(prompt: String, runs: [SubagentRun]) -> String {
        let completed = runs.filter { $0.state == .completed }.count
        let failed = runs.filter { $0.state == .failed }.count
        let sections = runs.map { run in
            """
            \(run.title):
            \(run.summary)
            """
        }.joined(separator: "\n\n")

        return """
        Agent swarm review for: \(prompt)

        Agents used: \(runs.count)
        Completed: \(completed)
        Failed: \(failed)

        \(sections)

        Recommended next move:
        Use the safety notes first, then ask me to run the next concrete action.
        """
    }

    private func selectedRoles(for prompt: String) -> [SubagentRole] {
        let lowered = prompt.lowercased()
        if lowered.contains("all 30") ||
            lowered.contains("30 agents") ||
            lowered.contains("full swarm") ||
            lowered.contains("whole swarm") {
            return Array(SubagentRole.allCases.prefix(30))
        }

        var roles: [SubagentRole] = [
            .planner,
            .decomposer,
            .researcher,
            .operatorAgent,
            .safetyReviewer,
            .synthesisLead
        ]

        append(.privacyGuardian, to: &roles, when: lowered.contains("privacy") || lowered.contains("identity") || lowered.contains("personal") || lowered.contains("public"))
        append(.securityAnalyst, to: &roles, when: lowered.contains("security") || lowered.contains("permission") || lowered.contains("keychain") || lowered.contains("api key"))
        append(.uxReviewer, to: &roles, when: lowered.contains("ui") || lowered.contains("interface") || lowered.contains("buggy") || lowered.contains("smooth"))
        append(.visualDesigner, to: &roles, when: lowered.contains("design") || lowered.contains("3d") || lowered.contains("website") || lowered.contains("beautiful"))
        append(.macOSSpecialist, to: &roles, when: lowered.contains("mac") || lowered.contains("macos") || lowered.contains("app") || lowered.contains("install"))
        append(.browserSpecialist, to: &roles, when: lowered.contains("browser") || lowered.contains("chrome") || lowered.contains("cloudflare") || lowered.contains("website"))
        append(.voiceDesigner, to: &roles, when: lowered.contains("voice") || lowered.contains("talk") || lowered.contains("mic") || lowered.contains("conversation"))
        append(.providerSpecialist, to: &roles, when: lowered.contains("provider") || lowered.contains("model") || lowered.contains("openai") || lowered.contains("nvidia"))
        append(.memoryCurator, to: &roles, when: lowered.contains("memory") || lowered.contains("remember") || lowered.contains("preference"))
        append(.automationDesigner, to: &roles, when: lowered.contains("automation") || lowered.contains("computer") || lowered.contains("click") || lowered.contains("type"))
        append(.qaTester, to: &roles, when: lowered.contains("bug") || lowered.contains("test") || lowered.contains("qa") || lowered.contains("verify"))
        append(.performanceOptimizer, to: &roles, when: lowered.contains("fast") || lowered.contains("slow") || lowered.contains("performance") || lowered.contains("response time"))
        append(.productStrategist, to: &roles, when: lowered.contains("product") || lowered.contains("startup") || lowered.contains("pay") || lowered.contains("customer"))
        append(.launchAdvisor, to: &roles, when: lowered.contains("launch") || lowered.contains("public") || lowered.contains("beta") || lowered.contains("release"))
        append(.growthMarketer, to: &roles, when: lowered.contains("marketing") || lowered.contains("growth") || lowered.contains("landing") || lowered.contains("users"))
        append(.copywriter, to: &roles, when: lowered.contains("copy") || lowered.contains("post") || lowered.contains("message") || lowered.contains("content"))
        append(.codeReviewer, to: &roles, when: lowered.contains("code") || lowered.contains("swift") || lowered.contains("implementation"))
        append(.dataAnalyst, to: &roles, when: lowered.contains("data") || lowered.contains("metric") || lowered.contains("analytics"))
        append(.fileManager, to: &roles, when: lowered.contains("file") || lowered.contains("download") || lowered.contains("upload") || lowered.contains("folder"))
        append(.accessibilityGuide, to: &roles, when: lowered.contains("accessibility") || lowered.contains("permission") || lowered.contains("screen"))
        append(.confirmationOfficer, to: &roles, when: lowered.contains("confirm") || lowered.contains("publish") || lowered.contains("send") || lowered.contains("delete"))
        append(.troubleshootingAgent, to: &roles, when: lowered.contains("not working") || lowered.contains("failed") || lowered.contains("error") || lowered.contains("fix"))
        append(.integrationArchitect, to: &roles, when: lowered.contains("mcp") || lowered.contains("connector") || lowered.contains("api") || lowered.contains("integration"))

        return Array(roles.prefix(12))
    }

    private func append(_ role: SubagentRole, to roles: inout [SubagentRole], when condition: Bool) {
        guard condition, !roles.contains(role) else { return }
        roles.append(role)
    }
}
