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
    public var lastAnswerWasWrong: Bool

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
        wrongCount: Int = 0,
        lastAnswerWasWrong: Bool = false
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
        self.lastAnswerWasWrong = lastAnswerWasWrong
    }

    public static func clampedLevel(_ level: Int) -> Int {
        min(maximumLevel, max(minimumLevel, level))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)

        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            englishText: try container.decode(String.self, forKey: .englishText),
            russianTranslation: try container.decode(String.self, forKey: .russianTranslation),
            comment: try container.decode(String.self, forKey: .comment),
            level: try container.decode(Int.self, forKey: .level),
            createdAt: createdAt,
            updatedAt: try container.decodeIfPresent(Date.self, forKey: .updatedAt),
            nextReviewAt: try container.decodeIfPresent(Date.self, forKey: .nextReviewAt),
            lastSeenAt: try container.decodeIfPresent(Date.self, forKey: .lastSeenAt),
            lastReviewedAt: try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt),
            lastDirection: try container.decodeIfPresent(ReviewDirection.self, forKey: .lastDirection),
            correctCount: try container.decode(Int.self, forKey: .correctCount),
            wrongCount: try container.decode(Int.self, forKey: .wrongCount),
            lastAnswerWasWrong: try container.decodeIfPresent(Bool.self, forKey: .lastAnswerWasWrong) ?? false
        )
    }
}
