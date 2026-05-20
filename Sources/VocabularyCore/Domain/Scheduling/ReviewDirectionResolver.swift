import Foundation

public enum ReviewDirectionResolver {
    public static func nextDirection<RNG: ReviewRandomGenerator>(
        after lastDirection: ReviewDirection?,
        rng: inout RNG
    ) -> ReviewDirection {
        if let lastDirection {
            return lastDirection.opposite
        }

        return rng.nextBool() ? .enToRu : .ruToEn
    }
}

public enum ReviewProgressRecorder {
    public static func markShown(
        _ word: VocabularyWord,
        direction: ReviewDirection,
        now: Date
    ) -> VocabularyWord {
        var updated = word
        updated.lastDirection = direction
        updated.lastSeenAt = now
        updated.updatedAt = now
        return updated
    }

    public static func applyFreeReviewAnswer(
        _ answer: ReviewAnswer,
        to word: VocabularyWord,
        now: Date
    ) -> VocabularyWord {
        var updated = word

        switch answer {
        case .correct:
            updated.correctCount += 1
            updated.lastAnswerWasWrong = false
        case .wrong:
            updated.wrongCount += 1
            updated.lastAnswerWasWrong = true
        }

        updated.lastReviewedAt = now
        updated.updatedAt = now
        return updated
    }
}
