import Foundation
import Testing
@testable import VocabularyCore

@Suite("Free Review")
struct FreeReviewPickerTests {
    @Test("free review correct answer does not change level or next review date")
    func freeReviewCorrectPreservesScheduling() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let nextReview = now.addingTimeInterval(7 * 86_400)
        let word = makeWord(level: 5, nextReviewAt: nextReview, correctCount: 2, wrongCount: 1)

        let updated = ReviewProgressRecorder.applyFreeReviewAnswer(.correct, to: word, now: now)

        #expect(updated.level == 5)
        #expect(updated.nextReviewAt == nextReview)
        #expect(updated.correctCount == 3)
        #expect(updated.wrongCount == 1)
        #expect(updated.lastReviewedAt == now)
    }

    @Test("free review wrong answer does not change level or next review date")
    func freeReviewWrongPreservesScheduling() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let nextReview = now.addingTimeInterval(7 * 86_400)
        let word = makeWord(level: 5, nextReviewAt: nextReview, correctCount: 2, wrongCount: 1)

        let updated = ReviewProgressRecorder.applyFreeReviewAnswer(.wrong, to: word, now: now)

        #expect(updated.level == 5)
        #expect(updated.nextReviewAt == nextReview)
        #expect(updated.correctCount == 2)
        #expect(updated.wrongCount == 2)
        #expect(updated.lastReviewedAt == now)
    }

    @Test("card shown updates last seen and last direction")
    func markShownUpdatesSeenFields() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let word = makeWord(level: 3)

        let updated = ReviewProgressRecorder.markShown(word, direction: .ruToEn, now: now)

        #expect(updated.lastSeenAt == now)
        #expect(updated.lastDirection == .ruToEn)
        #expect(updated.level == word.level)
        #expect(updated.nextReviewAt == word.nextReviewAt)
    }

    @Test("first direction is deterministic with seeded RNG")
    func firstDirectionIsDeterministic() {
        var firstRNG = SeededReviewRandomGenerator(seed: 42)
        var secondRNG = SeededReviewRandomGenerator(seed: 42)

        let first = ReviewDirectionResolver.nextDirection(after: nil, rng: &firstRNG)
        let second = ReviewDirectionResolver.nextDirection(after: nil, rng: &secondRNG)

        #expect(first == second)
    }

    @Test("first direction uses RNG threshold")
    func firstDirectionUsesRNGThreshold() {
        var lowRNG = FixedReviewRandomGenerator(values: [0.49])
        var highRNG = FixedReviewRandomGenerator(values: [0.50])

        #expect(ReviewDirectionResolver.nextDirection(after: nil, rng: &lowRNG) == .enToRu)
        #expect(ReviewDirectionResolver.nextDirection(after: nil, rng: &highRNG) == .ruToEn)
    }

    @Test("direction alternates after first review")
    func directionAlternates() {
        var rng = SeededReviewRandomGenerator(seed: 7)

        #expect(ReviewDirectionResolver.nextDirection(after: .enToRu, rng: &rng) == .ruToEn)
        #expect(ReviewDirectionResolver.nextDirection(after: .ruToEn, rng: &rng) == .enToRu)
    }

    @Test("exactly ten words have no duplicate in any ten-card window")
    func noDuplicateInTenCardWindowWithTenWords() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 10, now: now)
        var picker = FreeReviewPicker(rng: SeededReviewRandomGenerator(seed: 99))
        var ids: [UUID] = []

        for _ in 0..<100 {
            let id = picker.nextWordID(from: words, now: now)
            #expect(id != nil)
            ids.append(id!)
        }

        for index in 0...(ids.count - 10) {
            let window = ids[index..<(index + 10)]
            #expect(Set(window).count == 10)
        }
    }

    @Test("one-word deck can repeat")
    func oneWordDeckRepeats() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 1, now: now)
        var picker = FreeReviewPicker(rng: SeededReviewRandomGenerator(seed: 5))

        let ids = (0..<5).compactMap { _ in
            picker.nextWordID(from: words, now: now)
        }

        #expect(ids.count == 5)
        #expect(Set(ids).count == 1)
    }

    @Test("small decks avoid immediate repeats when possible")
    func smallDeckAvoidsImmediateRepeats() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 3, now: now)
        var picker = FreeReviewPicker(rng: SeededReviewRandomGenerator(seed: 12))
        var previous: UUID?

        for _ in 0..<30 {
            let id = picker.nextWordID(from: words, now: now)
            #expect(id != nil)
            #expect(id != previous)
            previous = id
        }
    }

    @Test("lower level scores higher with same age and stats")
    func lowerLevelScoresHigher() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let low = makeWord(level: 0, lastSeenAt: now.addingTimeInterval(-86_400))
        let high = makeWord(level: 9, lastSeenAt: now.addingTimeInterval(-86_400))

        #expect(FreeReviewScorer.weight(for: low, now: now) > FreeReviewScorer.weight(for: high, now: now))
    }

    @Test("older last seen scores higher with same level and stats")
    func olderWordScoresHigher() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let old = makeWord(level: 5, lastSeenAt: now.addingTimeInterval(-30 * 86_400))
        let recent = makeWord(level: 5, lastSeenAt: now)

        #expect(FreeReviewScorer.weight(for: old, now: now) > FreeReviewScorer.weight(for: recent, now: now))
    }

    @Test("wrong-heavy word gets a small priority boost")
    func wrongHeavyWordScoresHigher() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let wrongHeavy = makeWord(level: 5, lastSeenAt: now.addingTimeInterval(-86_400), correctCount: 1, wrongCount: 9)
        let correctHeavy = makeWord(level: 5, lastSeenAt: now.addingTimeInterval(-86_400), correctCount: 9, wrongCount: 1)

        #expect(FreeReviewScorer.weight(for: wrongHeavy, now: now) > FreeReviewScorer.weight(for: correctHeavy, now: now))
    }

    @Test("jitter stays inside expected bounds")
    func jitterBounds() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let word = makeWord(level: 5, lastSeenAt: now.addingTimeInterval(-86_400))
        let base = FreeReviewScorer.weight(for: word, now: now, jitter: 1.0)

        #expect(FreeReviewScorer.weight(for: word, now: now, jitter: 0.85) == base * 0.85)
        #expect(FreeReviewScorer.weight(for: word, now: now, jitter: 1.15) == base * 1.15)
    }

    @Test("randomized weight uses RNG jitter range")
    func randomizedWeightUsesRNGJitterRange() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let word = makeWord(level: 5, lastSeenAt: now.addingTimeInterval(-86_400))
        let base = FreeReviewScorer.weight(for: word, now: now, jitter: 1.0)
        var lowRNG = FixedReviewRandomGenerator(values: [0.0])
        var highRNG = FixedReviewRandomGenerator(values: [1.0])

        let low = FreeReviewScorer.randomizedWeight(for: word, now: now, rng: &lowRNG)
        let high = FreeReviewScorer.randomizedWeight(for: word, now: now, rng: &highRNG)

        #expect(abs(low - base * 0.85) < 0.000_000_001)
        #expect(abs(high - base * 1.15) < 0.000_000_001)
    }

    @Test("refill happens below threshold")
    func refillHappensBelowThreshold() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 20, now: now)
        var picker = FreeReviewPicker(
            rng: SeededReviewRandomGenerator(seed: 1),
            configuration: FreeReviewConfiguration(batchSize: 12, refillThreshold: 3)
        )

        picker.refillIfNeeded(from: words, now: now)

        #expect(picker.queuedCount == 12)
    }

    @Test("refill does not happen above threshold")
    func refillDoesNotHappenAboveThreshold() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 20, now: now)
        let queue = Array(words.prefix(5).map(\.id))
        var picker = FreeReviewPicker(
            rng: SeededReviewRandomGenerator(seed: 1),
            configuration: FreeReviewConfiguration(batchSize: 12, refillThreshold: 3),
            queue: queue
        )

        picker.refillIfNeeded(from: words, now: now)

        #expect(picker.queuedCount == 5)
    }

    @Test("empty queue refills even when threshold is zero")
    func emptyQueueRefillsWithZeroThreshold() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 5, now: now)
        var picker = FreeReviewPicker(
            rng: SeededReviewRandomGenerator(seed: 3),
            configuration: FreeReviewConfiguration(batchSize: 5, refillThreshold: 0)
        )

        let id = picker.nextWordID(from: words, now: now)

        #expect(id != nil)
    }

    @Test("generated batch respects virtual cooldown")
    func generatedBatchRespectsVirtualCooldown() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 10, now: now)
        var picker = FreeReviewPicker(rng: SeededReviewRandomGenerator(seed: 8))

        picker.refill(from: words, now: now)

        let ids = picker.queue
        #expect(ids.count == 50)

        for index in 0...(ids.count - 10) {
            let window = ids[index..<(index + 10)]
            #expect(Set(window).count == 10)
        }
    }

    @Test("queue is repaired after deck changes so cooldown still holds")
    func queueRepairAfterDeckChangesPreservesCooldown() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let originalWords = makeWords(count: 10, now: now)
        var picker = FreeReviewPicker(rng: SeededReviewRandomGenerator(seed: 23))

        picker.refill(from: originalWords, now: now)

        let replacement = makeWord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000099999")!,
            englishText: "replacement",
            russianTranslation: "замена",
            level: 2,
            createdAt: now,
            nextReviewAt: now.addingTimeInterval(86_400),
            lastSeenAt: now.addingTimeInterval(-12 * 86_400)
        )
        let changedWords = Array(originalWords.dropFirst()) + [replacement]
        var ids: [UUID] = []

        for _ in 0..<60 {
            let id = picker.nextWordID(from: changedWords, now: now)
            #expect(id != nil)
            ids.append(id!)
        }

        for index in 0...(ids.count - 10) {
            let window = ids[index..<(index + 10)]
            #expect(Set(window).count == 10)
        }
    }

    @Test("all words remain selectable over many refills")
    func allWordsRemainSelectable() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 15, now: now)
        var picker = FreeReviewPicker(rng: SeededReviewRandomGenerator(seed: 100))
        var seen = Set<UUID>()

        for _ in 0..<300 {
            if let id = picker.nextWordID(from: words, now: now) {
                seen.insert(id)
            }
        }

        #expect(seen == Set(words.map(\.id)))
    }

    @Test("generates a batch from ten thousand words inside performance budget")
    func tenThousandWordBatchGenerationPerformance() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let words = makeWords(count: 10_000, now: now)
        var picker = FreeReviewPicker(rng: SeededReviewRandomGenerator(seed: 777))

        let start = Date()
        picker.refill(from: words, now: now)
        let elapsed = Date().timeIntervalSince(start)

        #expect(picker.queuedCount == 50)
        #expect(elapsed < 2.0)
    }
}
