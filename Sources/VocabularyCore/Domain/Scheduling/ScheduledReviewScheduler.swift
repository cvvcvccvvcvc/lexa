import Foundation

public enum ScheduledReviewScheduler {
    public static let intervalDaysByLevel: [Int] = [
        0,
        1,
        2,
        4,
        7,
        14,
        14,
        14,
        14,
        14
    ]

    public static func intervalDays(for level: Int) -> Int {
        intervalDaysByLevel[VocabularyWord.clampedLevel(level)]
    }

    public static func isEligible(_ word: VocabularyWord, now: Date) -> Bool {
        word.nextReviewAt <= now
    }

    public static func eligibleWords(
        from words: [VocabularyWord],
        now: Date
    ) -> [VocabularyWord] {
        words
            .filter { isEligible($0, now: now) }
            .sorted {
                if $0.nextReviewAt == $1.nextReviewAt {
                    return $0.createdAt < $1.createdAt
                }

                return $0.nextReviewAt < $1.nextReviewAt
            }
    }

    public static func applyAnswer(
        _ answer: ReviewAnswer,
        to word: VocabularyWord,
        now: Date
    ) -> VocabularyWord {
        var updated = word
        let currentLevel = VocabularyWord.clampedLevel(word.level)

        switch answer {
        case .correct:
            updated.level = min(VocabularyWord.maximumLevel, currentLevel + 1)
            updated.correctCount += 1
        case .wrong:
            updated.level = max(VocabularyWord.minimumLevel, currentLevel - 1)
            updated.wrongCount += 1
        }

        updated.nextReviewAt = nextReviewDate(forLevel: updated.level, now: now)
        updated.lastReviewedAt = now
        updated.updatedAt = now
        return updated
    }

    public static func nextReviewDate(forLevel level: Int, now: Date) -> Date {
        now.addingTimeInterval(Double(intervalDays(for: level)) * 86_400)
    }
}
