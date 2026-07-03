import Foundation

struct VoiceDiagnosticItem: Identifiable, Equatable {
    enum Layer: String {
        case microphone = "Microphone"
        case speechToText = "Speech to text"
        case aiModel = "AI model"
        case textToSpeech = "Text to speech"
        case playback = "Playback"
        case interruption = "Interruption"
    }

    let id: String
    let layer: Layer
    let detail: String
    let state: ReadinessItem.State
}
