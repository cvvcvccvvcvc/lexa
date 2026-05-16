import Foundation

@MainActor
public protocol SpeechService: AnyObject {
    func speakEnglish(_ text: String)
}

@MainActor
public final class NoOpSpeechService: SpeechService {
    public init() {}

    public func speakEnglish(_ text: String) {}
}
