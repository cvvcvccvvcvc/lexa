import Foundation
import Testing
@testable import VocabularyCore

@Suite("Scheduled Review")
struct ScheduledReviewSchedulerTests {
    @Test("correct answer increases level and schedules by the new level interval")
    func correctAnswerUpdatesLevelAndNextReviewDate() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let word = makeWord(level: 2, nextReviewAt: now)

        let updated = ScheduledReviewScheduler.applyAnswer(.correct, to: word, now: now)

        #expect(updated.level == 3)
        #expect(updated.nextReviewAt == now.addingTimeInterval(4 * 86_400))
        #expect(updated.correctCount == word.correctCount + 1)
        #expect(updated.wrongCount == word.wrongCount)
        #expect(updated.lastReviewedAt == now)
    }

    @Test("wrong answer decreases level and schedules by the new level interval")
    func wrongAnswerUpdatesLevelAndNextReviewDate() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let word = makeWord(level: 4, nextReviewAt: now)

        let updated = ScheduledReviewScheduler.applyAnswer(.wrong, to: word, now: now)

        #expect(updated.level == 3)
        #expect(updated.nextReviewAt == now.addingTimeInterval(4 * 86_400))
        #expect(updated.correctCount == word.correctCount)
        #expect(updated.wrongCount == word.wrongCount + 1)
        #expect(updated.lastReviewedAt == now)
    }

    @Test("level zero remains immediately due after wrong answer")
    func wrongAnswerAtLevelZeroIsImmediatelyDue() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let word = makeWord(level: 0, nextReviewAt: now)

        let updated = ScheduledReviewScheduler.applyAnswer(.wrong, to: word, now: now)

        #expect(updated.level == 0)
        #expect(updated.nextReviewAt == now)
        #expect(ScheduledReviewScheduler.isEligible(updated, now: now))
    }

    @Test("correct answer at level nine stays at level nine")
    func correctAnswerAtMaximumLevelStaysAtMaximum() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let word = makeWord(level: 9, nextReviewAt: now)

        let updated = ScheduledReviewScheduler.applyAnswer(.correct, to: word, now: now)

        #expect(updated.level == 9)
        #expect(updated.nextReviewAt == now.addingTimeInterval(14 * 86_400))
    }

    @Test("scheduler clamps invalid input levels before applying answer")
    func schedulerClampsInvalidInputLevels() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        var negativeLevel = makeWord(level: 0, nextReviewAt: now)
        negativeLevel.level = -4
        var tooHighLevel = makeWord(level: 9, nextReviewAt: now)
        tooHighLevel.level = 12

        let corrected = ScheduledReviewScheduler.applyAnswer(.correct, to: negativeLevel, now: now)
        let wrong = ScheduledReviewScheduler.applyAnswer(.wrong, to: tooHighLevel, now: now)

        #expect(corrected.level == 1)
        #expect(corrected.nextReviewAt == now.addingTimeInterval(86_400))
        #expect(wrong.level == 8)
        #expect(wrong.nextReviewAt == now.addingTimeInterval(14 * 86_400))
    }

    @Test("eligible words are due or new words sorted by review date")
    func eligibleWordsAreSorted() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let later = makeWord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            level: 1,
            createdAt: now.addingTimeInterval(-20),
            nextReviewAt: now
        )
        let earlier = makeWord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            level: 1,
            createdAt: now.addingTimeInterval(-10),
            nextReviewAt: now.addingTimeInterval(-100)
        )
        let future = makeWord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            level: 1,
            nextReviewAt: now.addingTimeInterval(100)
        )

        let eligible = ScheduledReviewScheduler.eligibleWords(from: [later, future, earlier], now: now)

        #expect(eligible.map(\.id) == [earlier.id, later.id])
    }
}
