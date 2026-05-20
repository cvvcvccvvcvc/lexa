import Foundation

public enum FreeReviewScorer {
    public static func daysSince(_ date: Date?, now: Date) -> Double {
        guard let date else {
            return 30.0
        }

        return max(0, now.timeIntervalSince(date)) / 86_400.0
    }

    public static func weight(
        for word: VocabularyWord,
        now: Date,
        jitter: Double = 1.0,
        lastSeenAtOverride: Date? = nil
    ) -> Double {
        let days = daysSince(lastSeenAtOverride ?? word.lastSeenAt, now: now)
        let levelBoost = 1.0 + 0.35 * Double(VocabularyWord.maximumLevel - word.level)
        let ageBoost = 1.0 + log2(1.0 + days)
        let errorBoost: Double = word.lastAnswerWasWrong ? 5.0 : 1.0

        return max(0.0001, levelBoost * ageBoost * errorBoost * jitter)
    }

    public static func randomizedWeight<RNG: ReviewRandomGenerator>(
        for word: VocabularyWord,
        now: Date,
        rng: inout RNG,
        lastSeenAtOverride: Date? = nil
    ) -> Double {
        let jitter = rng.nextDouble(in: 0.85...1.15)
        return weight(
            for: word,
            now: now,
            jitter: jitter,
            lastSeenAtOverride: lastSeenAtOverride
        )
    }
}
