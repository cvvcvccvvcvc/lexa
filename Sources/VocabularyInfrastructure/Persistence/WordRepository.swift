import Foundation
import VocabularyCore

#if VOCABULARY_SWIFTDATA
import SwiftData

@MainActor
public final class WordRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func fetchWords() throws -> [VocabularyWord] {
        let descriptor = FetchDescriptor<WordRecord>(
            sortBy: [
                SortDescriptor(\.createdAt),
                SortDescriptor(\.englishText)
            ]
        )

        return try modelContext.fetch(descriptor).map(\.domainWord)
    }

    public func addWord(
        englishText: String,
        russianTranslation: String,
        comment: String,
        now: Date = Date()
    ) throws -> VocabularyWord {
        let word = VocabularyWord(
            englishText: englishText,
            russianTranslation: russianTranslation,
            comment: comment,
            level: 0,
            createdAt: now,
            updatedAt: now,
            nextReviewAt: now
        )
        modelContext.insert(WordRecord(word: word))
        try modelContext.save()
        return word
    }

    public func save(_ word: VocabularyWord) throws {
        if let record = try findRecord(id: word.id) {
            record.apply(word)
        } else {
            modelContext.insert(WordRecord(word: word))
        }

        try modelContext.save()
    }

    public func updateUserFields(
        id: UUID,
        englishText: String,
        russianTranslation: String,
        comment: String,
        now: Date = Date()
    ) throws -> VocabularyWord? {
        guard var word = try findRecord(id: id)?.domainWord else {
            return nil
        }

        word.englishText = englishText
        word.russianTranslation = russianTranslation
        word.comment = comment
        word.updatedAt = now
        try save(word)
        return word
    }

    public func deleteWord(id: UUID) throws {
        guard let record = try findRecord(id: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func findRecord(id: UUID) throws -> WordRecord? {
        let descriptor = FetchDescriptor<WordRecord>(
            predicate: #Predicate { record in
                record.id == id
            }
        )

        return try modelContext.fetch(descriptor).first
    }
}
#else
public enum WordRepositoryError: LocalizedError {
    case fallbackStoreLoadFailed(path: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case let .fallbackStoreLoadFailed(path, reason):
            "Could not read the local word store at \(path): \(reason). The store was not overwritten."
        }
    }
}

@MainActor
public final class WordRepository {
    public static let shared = WordRepository()

    private var words: [VocabularyWord]
    private let storeURL: URL
    private let loadError: WordRepositoryError?

    public init(storeURL: URL? = nil) {
        self.storeURL = storeURL ?? Self.defaultStoreURL()

        do {
            words = try Self.loadWords(from: self.storeURL)
            loadError = nil
        } catch {
            words = []
            loadError = .fallbackStoreLoadFailed(
                path: self.storeURL.path,
                reason: error.localizedDescription
            )
        }
    }

    public func fetchWords() throws -> [VocabularyWord] {
        try ensureStoreLoaded()

        return words.sorted {
            if $0.createdAt == $1.createdAt {
                return $0.englishText.localizedCaseInsensitiveCompare($1.englishText) == .orderedAscending
            }

            return $0.createdAt < $1.createdAt
        }
    }

    public func addWord(
        englishText: String,
        russianTranslation: String,
        comment: String,
        now: Date = Date()
    ) throws -> VocabularyWord {
        try ensureStoreLoaded()

        let word = VocabularyWord(
            englishText: englishText,
            russianTranslation: russianTranslation,
            comment: comment,
            level: 0,
            createdAt: now,
            updatedAt: now,
            nextReviewAt: now
        )
        words.append(word)
        try persist()
        return word
    }

    public func save(_ word: VocabularyWord) throws {
        try ensureStoreLoaded()

        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index] = word
        } else {
            words.append(word)
        }

        try persist()
    }

    public func updateUserFields(
        id: UUID,
        englishText: String,
        russianTranslation: String,
        comment: String,
        now: Date = Date()
    ) throws -> VocabularyWord? {
        try ensureStoreLoaded()

        guard let index = words.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        words[index].englishText = englishText
        words[index].russianTranslation = russianTranslation
        words[index].comment = comment
        words[index].updatedAt = now
        try persist()
        return words[index]
    }

    public func deleteWord(id: UUID) throws {
        try ensureStoreLoaded()

        words.removeAll { $0.id == id }
        try persist()
    }

    private func ensureStoreLoaded() throws {
        if let loadError {
            throw loadError
        }
    }

    private func persist() throws {
        let directory = storeURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder.vocabularyTracker.encode(words)
        try data.write(to: storeURL, options: .atomic)
    }

    private static func loadWords(from url: URL) throws -> [VocabularyWord] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder.vocabularyTracker.decode([VocabularyWord].self, from: data)
    }

    private static func defaultStoreURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory

        return baseURL
            .appendingPathComponent("VocabularyTracker", isDirectory: true)
            .appendingPathComponent("words.json")
    }
}

private extension JSONEncoder {
    static var vocabularyTracker: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var vocabularyTracker: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
#endif
