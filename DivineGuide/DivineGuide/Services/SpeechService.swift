import Foundation
import AVFoundation
import Speech

final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()

    @Published var isRecording: Bool = false

    func requestPermissions() async {
        _ = await SFSpeechRecognizer.requestAuthorization()
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    func startRecording(locale: Locale = Locale(identifier: "en-US"), onResult: @escaping (String) -> Void) throws {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                onResult(result.bestTranscription.formattedString)
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }
        isRecording = true
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }

    func speak(_ text: String, language: String) {
        let utterance = AVSpeechUtterance(string: text)
        switch language {
        case "hi": utterance.voice = AVSpeechSynthesisVoice(language: "hi-IN")
        case "te": utterance.voice = AVSpeechSynthesisVoice(language: "te-IN")
        case "ur": utterance.voice = AVSpeechSynthesisVoice(language: "ur-PK") ?? AVSpeechSynthesisVoice(language: "ar-SA")
        default: utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }
}