import CoreServices
import Foundation

public enum DictionaryLookupError: LocalizedError {
    case empty
    case notFound

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "Enter an English word to look up."
        case .notFound:
            return "No dictionary entry found. Enable a dictionary in System Settings → Dictionary."
        }
    }
}

public enum AppleDictionaryService {
    public static func lookup(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw DictionaryLookupError.empty
        }

        let range = CFRangeMake(0, trimmed.utf16.count)

        guard let result = DCSCopyTextDefinition(nil, trimmed as CFString, range)?.takeRetainedValue() else {
            throw DictionaryLookupError.notFound
        }

        let normalized = (result as String).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            throw DictionaryLookupError.notFound
        }

        return result as String
    }
}
