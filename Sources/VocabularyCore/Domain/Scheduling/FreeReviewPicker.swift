import Foundation

public struct FreeReviewConfiguration: Sendable {
    public var batchSize: Int
    public var refillThreshold: Int

    public init(batchSize: Int = 20, refillThreshold: Int = 5) {
        self.batchSize = max(1, batchSize)
        self.refillThreshold = max(0, refillThreshold)
    }

    public static let mvp = FreeReviewConfiguration(batchSize: 20, refillThreshold: 5)
}

public struct FreeReviewPicker<RNG: ReviewRandomGenerator> {
    public private(set) var queue: [UUID]
    public private(set) var recentIDs: [UUID]

    private var rng: RNG
    private let configuration: FreeReviewConfiguration

    public init(
        rng: RNG,
        configuration: FreeReviewConfiguration = .mvp,
        queue: [UUID] = [],
        recentIDs: [UUID] = []
    ) {
        self.rng = rng
        self.configuration = configuration
        self.queue = queue
        self.recentIDs = recentIDs
    }

    public var queuedCount: Int {
        queue.count
    }

    public static func recentWindowSize(wordCount: Int) -> Int {
        min(9, max(0, wordCount - 1))
    }

    public mutating func nextWord(
        from words: [VocabularyWord],
        now: Date
    ) -> VocabularyWord? {
        guard let id = nextWordID(from: words, now: now) else {
            return nil
        }

        return words.first { $0.id == id }
    }

    public mutating func nextWordID(
        from words: [VocabularyWord],
        now: Date
    ) -> UUID? {
        pruneState(for: words)

        guard !words.isEmpty else {
            return nil
        }

        refillIfNeeded(from: words, now: now)

        guard !queue.isEmpty else {
            return nil
        }

        let id = queue.removeFirst()
        rememberShown(id, wordCount: words.count)
        return id
    }

    public mutating func refillIfNeeded(
        from words: [VocabularyWord],
        now: Date
    ) {
        pruneState(for: words)

        guard queue.isEmpty || queue.count < configuration.refillThreshold else {
            return
        }

        refill(from: words, now: now)
    }

    public mutating func refill(
        from words: [VocabularyWord],
        now: Date
    ) {
        pruneState(for: words)

        guard !words.isEmpty, queue.count < configuration.batchSize else {
            return
        }

        let recentWindow = Self.recentWindowSize(wordCount: words.count)
        var virtualRecent = Array((recentIDs + queue).suffix(recentWindow))
        var virtualLastSeen = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0.lastSeenAt) })

        for id in queue {
            virtualLastSeen[id] = now
        }

        let needed = configuration.batchSize - queue.count

        for _ in 0..<needed {
            let excluded = Set(virtualRecent)

            guard let selected = weightedChoice(
                from: words,
                excluded: excluded,
                virtualLastSeen: virtualLastSeen,
                now: now
            ) else {
                break
            }

            queue.append(selected.id)
            virtualLastSeen[selected.id] = now
            append(selected.id, toRecentIDs: &virtualRecent, limit: recentWindow)
        }
    }

    private mutating func weightedChoice(
        from words: [VocabularyWord],
        excluded: Set<UUID>,
        virtualLastSeen: [UUID: Date?],
        now: Date
    ) -> VocabularyWord? {
        var weighted: [(word: VocabularyWord, weight: Double)] = []
        var total = 0.0

        for word in words where !excluded.contains(word.id) {
            let weight = FreeReviewScorer.randomizedWeight(
                for: word,
                now: now,
                rng: &rng,
                lastSeenAtOverride: virtualLastSeen[word.id] ?? nil
            )
            total += weight
            weighted.append((word, weight))
        }

        guard total > 0, !weighted.isEmpty else {
            return nil
        }

        var target = rng.nextDouble(in: 0..<total)

        for item in weighted {
            target -= item.weight
            if target <= 0 {
                return item.word
            }
        }

        return weighted.last?.word
    }

    private mutating func pruneState(for words: [VocabularyWord]) {
        let validIDs = Set(words.map(\.id))
        queue.removeAll { !validIDs.contains($0) }
        recentIDs.removeAll { !validIDs.contains($0) }
        trimRecentIDs(wordCount: words.count)
        repairQueuedCooldown(wordCount: words.count)
    }

    private mutating func rememberShown(_ id: UUID, wordCount: Int) {
        append(id, toRecentIDs: &recentIDs, limit: Self.recentWindowSize(wordCount: wordCount))
    }

    private mutating func trimRecentIDs(wordCount: Int) {
        let limit = Self.recentWindowSize(wordCount: wordCount)
        if recentIDs.count > limit {
            recentIDs.removeFirst(recentIDs.count - limit)
        }
    }

    private mutating func repairQueuedCooldown(wordCount: Int) {
        let limit = Self.recentWindowSize(wordCount: wordCount)

        guard limit > 0 else {
            return
        }

        var repaired: [UUID] = []
        var virtualRecent = Array(recentIDs.suffix(limit))

        for id in queue where !virtualRecent.contains(id) {
            repaired.append(id)
            append(id, toRecentIDs: &virtualRecent, limit: limit)
        }

        queue = repaired
    }

    private func append(_ id: UUID, toRecentIDs ids: inout [UUID], limit: Int) {
        guard limit > 0 else {
            ids.removeAll()
            return
        }

        ids.append(id)

        if ids.count > limit {
            ids.removeFirst(ids.count - limit)
        }
    }
}
