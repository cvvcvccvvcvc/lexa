import Foundation
import Translation

public enum TranslationError: LocalizedError {
    case empty
    case failed

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "Enter an English word to translate."
        case .failed:
            return "Translation failed. Try again."
        }
    }
}

public enum AppleTranslationService {
    public static func translate(
        _ text: String,
        using session: sending TranslationSession
    ) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw TranslationError.empty
        }

        do {
            let response = try await session.translate(trimmed)
            return response.targetText
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw TranslationError.failed
        }
    }
}
