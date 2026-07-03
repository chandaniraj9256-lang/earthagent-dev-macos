import AVFoundation
import Foundation
import Speech

final class SpeechInputService {
    struct AuthorizationSnapshot {
        let speechStatus: SFSpeechRecognizerAuthorizationStatus
        let microphoneStatus: AVAuthorizationStatus

        var isFullyAuthorized: Bool {
            speechStatus == .authorized && microphoneStatus == .authorized
        }

        var hasDeniedPermission: Bool {
            [.denied, .restricted].contains(speechStatus) || [.denied, .restricted].contains(microphoneStatus)
        }
    }

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var isStopping = false
    private var hasInstalledTap = false

    func authorizationSnapshot() -> AuthorizationSnapshot {
        AuthorizationSnapshot(
            speechStatus: SFSpeechRecognizer.authorizationStatus(),
            microphoneStatus: AVCaptureDevice.authorizationStatus(for: .audio)
        )
    }

    func start(onResult: @escaping (Result<SpeechRecognitionUpdate, Error>) -> Void) {
        isStopping = false
        let snapshot = authorizationSnapshot()
        if snapshot.isFullyAuthorized {
            DispatchQueue.main.async { [weak self] in
                self?.startEngine(onResult: onResult)
            }
            return
        }
        if snapshot.hasDeniedPermission {
            onResult(.failure(permissionError(for: snapshot)))
            return
        }

        requestSpeechThenMicrophone(onResult: onResult)
    }

    func stop() {
        isStopping = true
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }

    private func startEngine(onResult: @escaping (Result<SpeechRecognitionUpdate, Error>) -> Void) {
        stop()
        isStopping = false
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest, let recognizer, recognizer.isAvailable else {
            onResult(.failure(SpeechInputError.recognizerUnavailable))
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        hasInstalledTap = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            if hasInstalledTap {
                inputNode.removeTap(onBus: 0)
                hasInstalledTap = false
            }
            onResult(.failure(error))
            return
        }

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result {
                onResult(.success(SpeechRecognitionUpdate(
                    transcript: result.bestTranscription.formattedString,
                    isFinal: result.isFinal
                )))
            }
            if let error, self.isStopping == false {
                onResult(.failure(error))
            }
        }
    }

    private func requestSpeechThenMicrophone(onResult: @escaping (Result<SpeechRecognitionUpdate, Error>) -> Void) {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        if speechStatus == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                guard let self else { return }
                guard status == .authorized else {
                    onResult(.failure(SpeechInputError.speechPermissionDenied))
                    return
                }
                self.requestMicrophoneThenStart(onResult: onResult)
            }
            return
        }

        requestMicrophoneThenStart(onResult: onResult)
    }

    private func requestMicrophoneThenStart(onResult: @escaping (Result<SpeechRecognitionUpdate, Error>) -> Void) {
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if microphoneStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                guard granted else {
                    onResult(.failure(SpeechInputError.microphonePermissionDenied))
                    return
                }
                DispatchQueue.main.async {
                    self?.startEngine(onResult: onResult)
                }
            }
            return
        }

        guard microphoneStatus == .authorized else {
            onResult(.failure(SpeechInputError.microphonePermissionDenied))
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.startEngine(onResult: onResult)
        }
    }

    private func permissionError(for snapshot: AuthorizationSnapshot) -> SpeechInputError {
        if [.denied, .restricted].contains(snapshot.speechStatus) {
            return .speechPermissionDenied
        }
        if [.denied, .restricted].contains(snapshot.microphoneStatus) {
            return .microphonePermissionDenied
        }
        return .recognizerUnavailable
    }
}

struct SpeechRecognitionUpdate {
    let transcript: String
    let isFinal: Bool
}

enum SpeechInputError: LocalizedError {
    case speechPermissionDenied
    case microphonePermissionDenied
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .speechPermissionDenied:
            return "Speech recognition permission was denied."
        case .microphonePermissionDenied:
            return "Microphone permission was denied."
        case .recognizerUnavailable:
            return "Speech recognizer is unavailable."
        }
    }
}
