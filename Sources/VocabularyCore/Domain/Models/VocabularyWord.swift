import Foundation

public struct VocabularyWord: Codable, Identifiable, Hashable, Sendable {
    public static let minimumLevel = 0
    public static let maximumLevel = 9

    public var id: UUID
    public var englishText: String
    public var russianTranslation: String
    public var comment: String
    public var level: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var nextReviewAt: Date
    public var lastSeenAt: Date?
    public var lastReviewedAt: Date?
    public var lastDirection: ReviewDirection?
    public var correctCount: Int
    public var wrongCount: Int

    public init(
        id: UUID = UUID(),
        englishText: String,
        russianTranslation: String,
        comment: String = "",
        level: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        lastSeenAt: Date? = nil,
        lastReviewedAt: Date? = nil,
        lastDirection: ReviewDirection? = nil,
        correctCount: Int = 0,
        wrongCount: Int = 0
    ) {
        self.id = id
        self.englishText = englishText
        self.russianTranslation = russianTranslation
        self.comment = comment
        self.level = Self.clampedLevel(level)
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.nextReviewAt = nextReviewAt ?? createdAt
        self.lastSeenAt = lastSeenAt
        self.lastReviewedAt = lastReviewedAt
        self.lastDirection = lastDirection
        self.correctCount = max(0, correctCount)
        self.wrongCount = max(0, wrongCount)
    }

    public static func clampedLevel(_ level: Int) -> Int {
        min(maximumLevel, max(minimumLevel, level))
    }
}
