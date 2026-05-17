import Combine
import Foundation
import Translation
import VocabularyCore
import VocabularyInfrastructure

enum AddWordTranslationState: Equatable {
    case idle
    case translating
    case failed(String)
}

enum AddWordDictionaryState: Equatable {
    case idle
    case lookingUp
    case failed(String)
}

@MainActor
final class AddWordViewModel: ObservableObject {
    @Published var englishText = ""
    @Published var russianTranslation = ""
    @Published var comment = ""
    @Published var confirmationMessage: String?
    @Published var errorMessage: String?
    @Published var englishError: String?
    @Published var russianError: String?
    @Published var lastAddedEnglish: String?
    @Published var translationConfiguration: TranslationSession.Configuration?
    @Published var translationState: AddWordTranslationState = .idle
    @Published var dictionaryState: AddWordDictionaryState = .idle

    private var pendingTranslationText: String?

    var canSave: Bool {
        !englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !russianTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canTranslate: Bool {
        !englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            translationState != .translating
    }

    var canLookupDictionary: Bool {
        !englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            dictionaryState != .lookingUp
    }

    func addWord(repository: WordRepository) {
        let english = englishText.trimmingCharacters(in: .whitespacesAndNewlines)
        let russian = russianTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        englishError = nil
        russianError = nil

        guard !english.isEmpty, !russian.isEmpty else {
            if english.isEmpty {
                englishError = "Enter an English word."
            }

            if russian.isEmpty {
                russianError = "Enter a Russian translation."
            }

            errorMessage = nil
            confirmationMessage = nil
            return
        }

        do {
            let words = try repository.fetchWords()

            if words.contains(where: { $0.englishText.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(english) == .orderedSame }) {
                englishError = "You already have this word. Open it from Words to edit."
                confirmationMessage = nil
                lastAddedEnglish = nil
                return
            }

            _ = try repository.addWord(
                englishText: english,
                russianTranslation: russian,
                comment: note
            )
            englishText = ""
            russianTranslation = ""
            comment = ""
            confirmationMessage = "Word added."
            lastAddedEnglish = english
            errorMessage = nil
            translationState = .idle
            dictionaryState = .idle
        } catch {
            errorMessage = error.localizedDescription
            confirmationMessage = nil
            lastAddedEnglish = nil
        }
    }

    func clear() {
        englishText = ""
        russianTranslation = ""
        comment = ""
        englishError = nil
        russianError = nil
        errorMessage = nil
        confirmationMessage = nil
        lastAddedEnglish = nil
        translationState = .idle
        dictionaryState = .idle
    }

    func requestTranslation() {
        let trimmed = englishText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty, translationState != .translating else {
            return
        }

        translationState = .translating
        pendingTranslationText = trimmed

        if var existing = translationConfiguration {
            existing.invalidate()
            translationConfiguration = existing
        } else {
            translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "en"),
                target: Locale.Language(identifier: "ru")
            )
        }
    }

    func runTranslation(using session: sending TranslationSession) async {
        guard let text = pendingTranslationText else {
            return
        }

        pendingTranslationText = nil

        do {
            let translated = try await AppleTranslationService.translate(text, using: session)
            russianTranslation = translated
            russianError = nil
            translationState = .idle
        } catch is CancellationError {
            translationState = .idle
        } catch {
            translationState = .failed(error.localizedDescription)
        }
    }

    func dismissTranslationError() {
        if case .failed = translationState {
            translationState = .idle
        }
    }

    func lookupDictionary(options: DictionaryFormattingOptions) async {
        let trimmed = englishText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty, dictionaryState != .lookingUp else {
            return
        }

        dictionaryState = .lookingUp

        let raw: String

        do {
            raw = try await Task.detached(priority: .userInitiated) {
                try AppleDictionaryService.lookup(trimmed)
            }.value
        } catch {
            dictionaryState = .failed(error.localizedDescription)
            return
        }

        let entry = DictionaryEntryParser.parse(raw)
        let formatted = DictionaryEntryFormatter.format(entry, options: options)

        guard !formatted.isEmpty else {
            dictionaryState = .failed(DictionaryLookupError.notFound.localizedDescription)
            return
        }

        comment = formatted
        dictionaryState = .idle
    }

    func dismissDictionaryError() {
        if case .failed = dictionaryState {
            dictionaryState = .idle
        }
    }
}
