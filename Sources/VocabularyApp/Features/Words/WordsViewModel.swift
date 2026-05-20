import Combine
import Foundation
import VocabularyCore
import VocabularyInfrastructure

@MainActor
final class WordsViewModel: ObservableObject {
    @Published var words: [VocabularyWord] = []
    @Published var selectedID: UUID?
    @Published var englishText = ""
    @Published var russianTranslation = ""
    @Published var comment = ""
    @Published var errorMessage: String?
    @Published var confirmationMessage: String?
    @Published var isDeleteConfirmationPresented = false
    @Published var hasLoaded = false

    private let speechService: any SpeechService

    init(speechService: any SpeechService = AppleSpeechService()) {
        self.speechService = speechService
    }

    var selectedWord: VocabularyWord? {
        guard let selectedID else {
            return nil
        }

        return words.first { $0.id == selectedID }
    }

    var canSave: Bool {
        selectedID != nil &&
            !englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !russianTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func load(repository: WordRepository) {
        do {
            words = try repository.fetchWords()

            if let selectedID, words.contains(where: { $0.id == selectedID }) {
                select(id: selectedID)
            } else {
                selectedID = nil
                select(id: nil)
            }

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        hasLoaded = true
    }

    func select(id: UUID?) {
        selectedID = id

        guard let word = selectedWord else {
            englishText = ""
            russianTranslation = ""
            comment = ""
            return
        }

        englishText = word.englishText
        russianTranslation = word.russianTranslation
        comment = word.comment
    }

    func save(repository: WordRepository) {
        guard let selectedID else {
            return
        }

        let english = englishText.trimmingCharacters(in: .whitespacesAndNewlines)
        let russian = russianTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = comment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !english.isEmpty, !russian.isEmpty else {
            errorMessage = "Enter both English and Russian before saving."
            confirmationMessage = nil
            return
        }

        do {
            _ = try repository.updateUserFields(
                id: selectedID,
                englishText: english,
                russianTranslation: russian,
                comment: note
            )
            words = try repository.fetchWords()
            select(id: selectedID)
            confirmationMessage = "Changes saved."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            confirmationMessage = nil
        }
    }

    func deleteSelected(repository: WordRepository) {
        guard let selectedID else {
            return
        }

        do {
            try repository.deleteWord(id: selectedID)
            words = try repository.fetchWords()
            self.selectedID = nil
            select(id: self.selectedID)
            confirmationMessage = "Word deleted."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            confirmationMessage = nil
        }
    }

    func speakSelectedEnglish() {
        guard let selectedWord else {
            return
        }

        speechService.speakEnglish(selectedWord.englishText)
    }
}
