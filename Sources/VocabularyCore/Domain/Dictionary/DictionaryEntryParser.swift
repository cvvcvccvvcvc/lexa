import Foundation

public enum DictionaryEntryParser {
    private static let partOfSpeechKeywords: [String] = [
        "noun", "verb", "adjective", "adverb",
        "preposition", "pronoun", "conjunction", "determiner",
        "exclamation", "interjection", "abbreviation",
        "prefix", "suffix", "contraction", "numeral", "article"
    ]

    private static let sectionHeaders = ["DERIVATIVES", "ORIGIN", "PHRASES", "PHRASAL VERBS", "USAGE", "NOTE"]

    public static func parse(_ raw: String) -> DictionaryEntry {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return DictionaryEntry(raw: raw)
        }

        var working = trimmed
        var pronunciation: String? = nil

        if let extracted = extractLeadingPronunciation(from: working) {
            pronunciation = extracted.pronunciation
            working = extracted.remainder
        }

        let sectioning = splitSections(working)
        let senses = parseSenses(sectioning.main)

        return DictionaryEntry(
            pronunciation: pronunciation,
            senses: senses,
            origin: sectioning.sections["ORIGIN"],
            phrases: sectioning.sections["PHRASES"],
            derivatives: sectioning.sections["DERIVATIVES"],
            usage: sectioning.sections["USAGE"],
            note: sectioning.sections["NOTE"],
            raw: raw
        )
    }

    // MARK: - Pronunciation

    private static func extractLeadingPronunciation(from text: String) -> (pronunciation: String, remainder: String)? {
        guard let firstPipe = text.range(of: " | ") else {
            return nil
        }

        let afterFirst = text[firstPipe.upperBound...]

        guard let secondPipe = afterFirst.range(of: " | ") else {
            return nil
        }

        let pron = String(afterFirst[..<secondPipe.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let remainder = String(afterFirst[secondPipe.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !pron.isEmpty, pron.count <= 80 else {
            return nil
        }

        let posPattern = "\\b(\(partOfSpeechKeywords.joined(separator: "|")))\\b"
        if pron.range(of: posPattern, options: .regularExpression) != nil {
            return nil
        }

        return (pron, remainder)
    }

    // MARK: - Section splitting

    private struct Sectioning {
        var main: String
        var sections: [String: String]
    }

    private static func splitSections(_ text: String) -> Sectioning {
        var positions: [(name: String, range: Range<String.Index>)] = []

        for header in sectionHeaders {
            if let range = text.range(of: " \(header) ") {
                positions.append((header, range))
            }
        }

        positions.sort { $0.range.lowerBound < $1.range.lowerBound }

        guard let first = positions.first else {
            return Sectioning(main: text, sections: [:])
        }

        let main = String(text[..<first.range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)

        var collected: [String: String] = [:]
        for (index, entry) in positions.enumerated() {
            let start = entry.range.upperBound
            let end: String.Index = (index + 1 < positions.count) ? positions[index + 1].range.lowerBound : text.endIndex
            let content = String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                collected[entry.name] = content
            }
        }

        return Sectioning(main: main, sections: collected)
    }

    // MARK: - Sense parsing

    private static func parseSenses(_ text: String) -> [DictionaryEntry.Sense] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return []
        }

        let pattern = "(?<![A-Za-z])(\(partOfSpeechKeywords.joined(separator: "|")))(?![A-Za-z])"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            let unit = parseSenseUnit(trimmed)
            return [DictionaryEntry.Sense(definition: unit.definition, examples: unit.examples)]
        }

        let nsText = trimmed as NSString
        let rawMatches = regex.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsText.length))
        let matches = rawMatches.filter { !isInsideBrackets(match: $0, in: nsText) }

        guard !matches.isEmpty else {
            let unit = parseSenseUnit(trimmed)
            return [DictionaryEntry.Sense(definition: unit.definition, examples: unit.examples)]
        }

        var senses: [DictionaryEntry.Sense] = []

        for index in 0..<matches.count {
            let match = matches[index]
            let pos = nsText.substring(with: match.range)
            let contentStart = match.range.location + match.range.length
            let contentEnd = (index + 1 < matches.count) ? matches[index + 1].range.location : nsText.length
            let contentRange = NSRange(location: contentStart, length: max(0, contentEnd - contentStart))
            let content = nsText
                .substring(with: contentRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let parts = splitByBullet(content)
            let mainContent = parts.first ?? ""
            let subContents = Array(parts.dropFirst())

            let mainUnit = parseSenseUnit(mainContent)
            let subSenses = subContents.map { sub -> DictionaryEntry.SubSense in
                let unit = parseSenseUnit(sub)
                return DictionaryEntry.SubSense(definition: unit.definition, examples: unit.examples)
            }

            senses.append(DictionaryEntry.Sense(
                partOfSpeech: pos,
                definition: mainUnit.definition,
                examples: mainUnit.examples,
                subSenses: subSenses
            ))
        }

        return senses
    }

    private static func isInsideBrackets(match: NSTextCheckingResult, in text: NSString) -> Bool {
        guard match.range.location > 0 else {
            return false
        }

        let prefix = text.substring(to: match.range.location)
        var depth = 0

        for character in prefix {
            if character == "[" {
                depth += 1
            } else if character == "]" {
                depth -= 1
            }
        }

        return depth > 0
    }

    private static func splitByBullet(_ text: String) -> [String] {
        text
            .components(separatedBy: " • ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func parseSenseUnit(_ text: String) -> (definition: String, examples: [String]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return ("", [])
        }

        guard let colonRange = trimmed.range(of: ": ") else {
            return (trimmed, [])
        }

        let definition = String(trimmed[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let examplesBlob = String(trimmed[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

        let examples = examplesBlob
            .components(separatedBy: " | ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return (definition, examples)
    }
}
