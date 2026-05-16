import Combine
import Foundation
import VocabularyCore
import VocabularyInfrastructure

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

    var canSave: Bool {
        !englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !russianTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
    }
}
