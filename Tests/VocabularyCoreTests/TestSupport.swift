import Foundation
@testable import VocabularyCore

struct FixedReviewRandomGenerator: ReviewRandomGenerator {
    var values: [Double]

    mutating func nextUnitDouble() -> Double {
        if values.isEmpty {
            return 0
        }

        return values.removeFirst()
    }
}

func makeWord(
    id: UUID = UUID(),
    englishText: String = "word",
    russianTranslation: String = "слово",
    comment: String = "",
    level: Int = 0,
    createdAt: Date = Date(timeIntervalSince1970: 1_000_000),
    updatedAt: Date? = nil,
    nextReviewAt: Date? = nil,
    lastSeenAt: Date? = nil,
    lastReviewedAt: Date? = nil,
    lastDirection: ReviewDirection? = nil,
    correctCount: Int = 0,
    wrongCount: Int = 0,
    lastAnswerWasWrong: Bool = false
) -> VocabularyWord {
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
        lastDirection: lastDirection,
        correctCount: correctCount,
        wrongCount: wrongCount,
        lastAnswerWasWrong: lastAnswerWasWrong
    )
}

func makeWords(count: Int, now: Date) -> [VocabularyWord] {
    (0..<count).map { index in
        let uuid = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!

        return makeWord(
            id: uuid,
            englishText: "word \(index)",
            russianTranslation: "слово \(index)",
            level: index % 10,
            createdAt: now.addingTimeInterval(Double(-index)),
            nextReviewAt: now.addingTimeInterval(86_400),
            lastSeenAt: now.addingTimeInterval(Double(-index) * 86_400),
            correctCount: index % 5,
            wrongCount: index % 3
        )
    }
}
