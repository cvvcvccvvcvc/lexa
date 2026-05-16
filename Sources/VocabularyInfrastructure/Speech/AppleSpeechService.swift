import AVFoundation
import Foundation

@MainActor
public final class AppleSpeechService: SpeechService {
    private let synthesizer = AVSpeechSynthesizer()

    public init() {}

    public func speakEnglish(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}
