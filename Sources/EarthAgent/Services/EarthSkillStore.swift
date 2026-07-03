import Foundation

final class EarthSkillStore {
    func load() -> [EarthSkill] {
        EarthSkill.builtIns
    }
}

final class EarthSkillMatcher {
    func matches(for text: String, skills: [EarthSkill]) -> [SkillMatch] {
        let lowered = text.lowercased()
        let matches = skills.compactMap { skill -> SkillMatch? in
            let triggerScore = skill.triggerPhrases.reduce(0) { score, phrase in
                lowered.contains(phrase.lowercased()) ? score + 3 : score
            }
            let nameScore = lowered.contains(skill.name.lowercased()) ? 2 : 0
            let score = triggerScore + nameScore
            return score > 0 ? SkillMatch(skill: skill, score: score) : nil
        }
        return matches.sorted { $0.score > $1.score }
    }
}
