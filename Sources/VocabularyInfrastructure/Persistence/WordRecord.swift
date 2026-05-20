#if VOCABULARY_SWIFTDATA
import Foundation
import SwiftData
import VocabularyCore

@Model
public final class WordRecord {
    @Attribute(.unique) public var id: UUID
    public var englishText: String
    public var russianTranslation: String
    public var comment: String
    public var level: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var nextReviewAt: Date
    public var lastSeenAt: Date?
    public var lastReviewedAt: Date?
    public var lastDirectionRaw: String?
    public var correctCount: Int
    public var wrongCount: Int
    public var lastAnswerWasWrong: Bool = false

    public init(word: VocabularyWord) {
        id = word.id
        englishText = word.englishText
        russianTranslation = word.russianTranslation
        comment = word.comment
        level = word.level
        createdAt = word.createdAt
        updatedAt = word.updatedAt
        nextReviewAt = word.nextReviewAt
        lastSeenAt = word.lastSeenAt
        lastReviewedAt = word.lastReviewedAt
        lastDirectionRaw = word.lastDirection?.rawValue
        correctCount = word.correctCount
        wrongCount = word.wrongCount
        lastAnswerWasWrong = word.lastAnswerWasWrong
    }

    public var domainWord: VocabularyWord {
        VocabularyWord(
            id: id,
            englishText: englishText,
            russianTranslation: russianTranslation,
            comment: comment,
            level: level,
            createdAt: createdAt,
            updatedAt: updatedAt,
            nextReviewAt: nextReviewAt,
            lastSeenAt: lastSeenAt,
            lastReviewedAt: lastReviewedAt,
            lastDirection: lastDirectionRaw.flatMap(ReviewDirection.init(rawValue:)),
            correctCount: correctCount,
            wrongCount: wrongCount,
            lastAnswerWasWrong: lastAnswerWasWrong
        )
    }

    public func apply(_ word: VocabularyWord) {
        englishText = word.englishText
        russianTranslation = word.russianTranslation
        comment = word.comment
        level = word.level
        createdAt = word.createdAt
        updatedAt = word.updatedAt
        nextReviewAt = word.nextReviewAt
        lastSeenAt = word.lastSeenAt
        lastReviewedAt = word.lastReviewedAt
        lastDirectionRaw = word.lastDirection?.rawValue
        correctCount = word.correctCount
        wrongCount = word.wrongCount
        lastAnswerWasWrong = word.lastAnswerWasWrong
    }
}
#endif
