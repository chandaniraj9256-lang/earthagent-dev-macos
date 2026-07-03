import Foundation

struct VoiceTurnSettings: Codable, Equatable {
    var silenceDelay: TimeInterval
    var finalTranscriptDelay: TimeInterval
    var minimumWordCount: Int
    var maximumListeningDuration: TimeInterval
    var restartListeningDelay: TimeInterval
    var macSpeechRate: Double

    static let standard = VoiceTurnSettings(
        silenceDelay: 1.15,
        finalTranscriptDelay: 0.55,
        minimumWordCount: 2,
        maximumListeningDuration: 22,
        restartListeningDelay: 0.28,
        macSpeechRate: 188
    )

    var normalized: VoiceTurnSettings {
        VoiceTurnSettings(
            silenceDelay: silenceDelay.clamped(to: 0.6...2.6),
            finalTranscriptDelay: finalTranscriptDelay.clamped(to: 0.25...1.4),
            minimumWordCount: minimumWordCount.clamped(to: 1...5),
            maximumListeningDuration: maximumListeningDuration.clamped(to: 8...45),
            restartListeningDelay: restartListeningDelay.clamped(to: 0.1...1.2),
            macSpeechRate: macSpeechRate.clamped(to: 145...230)
        )
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
