import AppKit
import AVFoundation

enum SpeechOutputError: LocalizedError {
    case unsupportedProvider(String)
    case invalidURL
    case providerError(String)
    case emptyAudio

    var errorDescription: String? {
        switch self {
        case .unsupportedProvider(let provider):
            return "\(provider) voice playback is not wired yet."
        case .invalidURL:
            return "The voice provider URL is not valid."
        case .providerError(let message):
            return message
        case .emptyAudio:
            return "The voice provider returned empty audio."
        }
    }
}

final class SpeechOutputService: NSObject, NSSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    private let synthesizer = NSSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var speechTask: Task<Void, Never>?
    private var completion: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func availableMacVoiceIDs() -> [String] {
        let voiceIDs = NSSpeechSynthesizer.availableVoices.map(\.rawValue)
        return ["system-default"] + voiceIDs.sorted { macVoiceLabel(for: $0).localizedCaseInsensitiveCompare(macVoiceLabel(for: $1)) == .orderedAscending }
    }

    func macVoiceLabel(for voiceID: String) -> String {
        guard voiceID != "system-default" else { return "System Default" }
        let voiceName = NSSpeechSynthesizer.VoiceName(rawValue: voiceID)
        let attributes = NSSpeechSynthesizer.attributes(forVoice: voiceName)
        let name = attributes[NSSpeechSynthesizer.VoiceAttributeKey.name] as? String ?? voiceID
        let locale = attributes[NSSpeechSynthesizer.VoiceAttributeKey.localeIdentifier] as? String
        if let locale, !locale.isEmpty {
            return "\(name) (\(locale))"
        }
        return name
    }

    func speak(
        _ text: String,
        configuration: VoiceConfiguration = .macOS,
        rate: Float = 190,
        apiKey: String? = nil,
        onFallback: ((String) -> Void)? = nil,
        completion: @escaping () -> Void
    ) {
        stop(notifyCompletion: false)
        self.completion = completion

        guard configuration.providerID != "macos" else {
            speakWithMac(text, voiceID: configuration.voiceID, rate: rate)
            return
        }

        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onFallback?("Voice API key missing. Using macOS voice.")
            speakWithMac(text, voiceID: "system-default", rate: rate)
            return
        }

        speechTask = Task { [weak self] in
            guard let self else { return }
            do {
                let audio = try await self.fetchSpeechAudio(text: text, configuration: configuration, apiKey: apiKey)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.playAudio(audio, fallbackText: text, onFallback: onFallback)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    onFallback?("\(error.localizedDescription) Using macOS voice.")
                    self.speakWithMac(text, voiceID: "system-default", rate: rate)
                }
            }
        }
    }

    func stop() {
        stop(notifyCompletion: false)
    }

    func stop(notifyCompletion: Bool) {
        speechTask?.cancel()
        speechTask = nil
        if player?.isPlaying == true {
            player?.stop()
        }
        player = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
        }
        if notifyCompletion {
            completion?()
        }
        completion = nil
    }

    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        completion?()
        completion = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        completion?()
        completion = nil
        self.player = nil
    }

    private func speakWithMac(_ text: String, voiceID: String = "system-default", rate: Float = 190) {
        synthesizer.rate = rate
        if voiceID != "system-default" {
            _ = synthesizer.setVoice(NSSpeechSynthesizer.VoiceName(rawValue: voiceID))
        } else {
            _ = synthesizer.setVoice(nil)
        }
        if !synthesizer.startSpeaking(text) {
            completion?()
            completion = nil
        }
    }

    private func playAudio(_ data: Data, fallbackText: String, onFallback: ((String) -> Void)?) {
        do {
            let audioPlayer = try AVAudioPlayer(data: data)
            player = audioPlayer
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            if !audioPlayer.play() {
                player = nil
                onFallback?("Could not start provider audio. Using macOS voice.")
                speakWithMac(fallbackText, voiceID: "system-default")
            }
        } catch {
            onFallback?("Could not play provider audio. Using macOS voice.")
            speakWithMac(fallbackText, voiceID: "system-default")
        }
    }

    private func fetchSpeechAudio(text: String, configuration: VoiceConfiguration, apiKey: String) async throws -> Data {
        switch configuration.providerID {
        case "elevenlabs":
            return try await fetchElevenLabsSpeech(text: text, configuration: configuration, apiKey: apiKey)
        case "openai":
            return try await fetchOpenAISpeech(text: text, configuration: configuration, apiKey: apiKey)
        default:
            throw SpeechOutputError.unsupportedProvider(configuration.providerName)
        }
    }

    private func fetchElevenLabsSpeech(text: String, configuration: VoiceConfiguration, apiKey: String) async throws -> Data {
        let base = normalizedBaseURL(configuration.baseURL)
        guard let url = URL(string: "\(base)/text-to-speech/\(configuration.voiceID)") else {
            throw SpeechOutputError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(ElevenLabsSpeechRequest(
            text: text,
            model_id: configuration.modelName
        ))
        return try await audioData(for: request)
    }

    private func fetchOpenAISpeech(text: String, configuration: VoiceConfiguration, apiKey: String) async throws -> Data {
        let base = normalizedBaseURL(configuration.baseURL)
        guard let url = URL(string: "\(base)/audio/speech") else {
            throw SpeechOutputError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(OpenAISpeechRequest(
            model: configuration.modelName,
            input: text,
            voice: configuration.voiceID,
            response_format: "mp3"
        ))
        return try await audioData(for: request)
    }

    private func audioData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SpeechOutputError.providerError("The voice provider returned an invalid response.")
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data.prefix(400), encoding: .utf8) ?? "Voice provider failed with HTTP \(http.statusCode)."
            throw SpeechOutputError.providerError(message)
        }
        guard !data.isEmpty else { throw SpeechOutputError.emptyAudio }
        return data
    }

    private func normalizedBaseURL(_ value: String) -> String {
        var clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while clean.hasSuffix("/") {
            clean.removeLast()
        }
        return clean
    }
}

private struct ElevenLabsSpeechRequest: Encodable {
    let text: String
    let model_id: String
}

private struct OpenAISpeechRequest: Encodable {
    let model: String
    let input: String
    let voice: String
    let response_format: String
}
