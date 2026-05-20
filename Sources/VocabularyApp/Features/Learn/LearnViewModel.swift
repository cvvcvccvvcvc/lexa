import Combine
import Foundation
import VocabularyCore
import VocabularyInfrastructure

enum LearnPhase {
    case scheduled
    case free
}

struct ReviewCard: Identifiable, Equatable {
    var word: VocabularyWord
    var direction: ReviewDirection

    var id: UUID {
        word.id
    }

    var prompt: String {
        switch direction {
        case .enToRu:
            word.englishText
        case .ruToEn:
            word.russianTranslation
        }
    }

    var answer: String {
        switch direction {
        case .enToRu:
            word.russianTranslation
        case .ruToEn:
            word.englishText
        }
    }

    var isEnglishPrompt: Bool {
        direction == .enToRu
    }

    var directionLabel: String {
        switch direction {
        case .enToRu:
            "EN -> RU"
        case .ruToEn:
            "RU -> EN"
        }
    }
}

@MainActor
final class LearnViewModel: ObservableObject {
    @Published var currentCard: ReviewCard?
    @Published var isAnswerVisible = false
    @Published var phase: LearnPhase = .scheduled
    @Published var errorMessage: String?
    @Published var scheduledDueCount = 0
    @Published var hasLoaded = false

    private var freeReviewPicker = FreeReviewPicker(rng: SystemReviewRandomGenerator())
    private var directionRNG = SystemReviewRandomGenerator()
    private let speechService: any SpeechService

    init(speechService: any SpeechService) {
        self.speechService = speechService
    }

    var isFreeReviewActive: Bool {
        phase == .free && currentCard != nil
    }

    var canSpeakCurrentEnglish: Bool {
        guard let currentCard else {
            return false
        }

        return currentCard.direction == .enToRu || isAnswerVisible
    }

    func load(repository: WordRepository) {
        do {
            if currentCard == nil {
                try presentNextCard(repository: repository)
            } else {
                try reloadCurrentCard(repository: repository)
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        hasLoaded = true
    }

    func revealAnswer() {
        guard currentCard != nil else {
            return
        }

        isAnswerVisible = true
    }

    func speakCurrentEnglish() {
        guard canSpeakCurrentEnglish, let currentCard else {
            return
        }

        speechService.speakEnglish(currentCard.word.englishText)
    }

    func answer(
        _ answer: ReviewAnswer,
        repository: WordRepository,
        onWordsChanged: () -> Void = {}
    ) {
        guard isAnswerVisible, let currentCard else {
            return
        }

        let now = Date()
        let updatedWord: VocabularyWord

        switch phase {
        case .scheduled:
            updatedWord = ScheduledReviewScheduler.applyAnswer(answer, to: currentCard.word, now: now)
        case .free:
            updatedWord = ReviewProgressRecorder.applyFreeReviewAnswer(answer, to: currentCard.word, now: now)
        }

        do {
            try repository.save(updatedWord)
            try presentNextCard(repository: repository)
            onWordsChanged()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func presentNextCard(repository: WordRepository) throws {
        let words = try repository.fetchWords()

        guard !words.isEmpty else {
            currentCard = nil
            isAnswerVisible = false
            phase = .scheduled
            scheduledDueCount = 0
            return
        }

        let now = Date()

        let scheduledWords = ScheduledReviewScheduler.eligibleWords(from: words, now: now)
        scheduledDueCount = scheduledWords.count

        if let scheduledWord = scheduledWords.first {
            phase = .scheduled
            try present(word: scheduledWord, repository: repository, now: now)
            return
        }

        phase = .free
        scheduledDueCount = 0

        if let freeReviewWord = freeReviewPicker.nextWord(from: words, now: now) {
            try present(word: freeReviewWord, repository: repository, now: now)
        } else {
            currentCard = nil
            isAnswerVisible = false
        }
    }

    private func present(
        word: VocabularyWord,
        repository: WordRepository,
        now: Date
    ) throws {
        let direction = ReviewDirectionResolver.nextDirection(
            after: word.lastDirection,
            rng: &directionRNG
        )
        let shownWord = ReviewProgressRecorder.markShown(word, direction: direction, now: now)
        try repository.save(shownWord)
        currentCard = ReviewCard(word: shownWord, direction: direction)
        isAnswerVisible = false
    }

    private func reloadCurrentCard(repository: WordRepository) throws {
        guard let currentCard else {
            try presentNextCard(repository: repository)
            return
        }

        let words = try repository.fetchWords()
        scheduledDueCount = ScheduledReviewScheduler.eligibleWords(from: words, now: Date()).count

        guard let updatedWord = words.first(where: { $0.id == currentCard.word.id }) else {
            self.currentCard = nil
            try presentNextCard(repository: repository)
            return
        }

        self.currentCard = ReviewCard(word: updatedWord, direction: currentCard.direction)
    }
}
