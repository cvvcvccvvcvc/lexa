import Foundation

public enum DictionaryEntryFormatter {
    public static func format(_ entry: DictionaryEntry, options: DictionaryFormattingOptions) -> String {
        var lines: [String] = []

        if options.includePronunciation, let pronunciation = entry.pronunciation, !pronunciation.isEmpty {
            lines.append(pronunciation)
            lines.append("")
        }

        for sense in entry.senses {
            lines.append(senseLine(sense))

            if options.includeExamples, !sense.examples.isEmpty {
                lines.append("e.g. " + sense.examples.joined(separator: "; "))
            }

            for subSense in sense.subSenses {
                lines.append("• " + subSense.definition)

                if options.includeExamples, !subSense.examples.isEmpty {
                    lines.append("e.g. " + subSense.examples.joined(separator: "; "))
                }
            }
        }

        if options.includeExtras {
            for (label, content) in extras(from: entry) {
                guard let content, !content.isEmpty else {
                    continue
                }

                lines.append("")
                lines.append("\(label): \(content)")
            }
        }

        if entry.senses.isEmpty, lines.isEmpty {
            return normalizeWhitespace(entry.raw)
        }

        return collapseBlankLines(lines.joined(separator: "\n"))
    }

    private static func senseLine(_ sense: DictionaryEntry.Sense) -> String {
        if let pos = sense.partOfSpeech, !pos.isEmpty {
            return "\(pos) — \(sense.definition)"
        }

        return sense.definition
    }

    private static func extras(from entry: DictionaryEntry) -> [(String, String?)] {
        [
            ("Phrases", entry.phrases),
            ("Origin", entry.origin),
            ("Derivatives", entry.derivatives),
            ("Usage", entry.usage),
            ("Note", entry.note)
        ]
    }

    private static func normalizeWhitespace(_ text: String) -> String {
        let collapsed = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func collapseBlankLines(_ text: String) -> String {
        var result: [String] = []
        var previousWasEmpty = false

        for line in text.components(separatedBy: "\n") {
            let isEmpty = line.trimmingCharacters(in: .whitespaces).isEmpty

            if isEmpty, previousWasEmpty {
                continue
            }

            result.append(line)
            previousWasEmpty = isEmpty
        }

        while result.first?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeFirst()
        }

        while result.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeLast()
        }

        return result.joined(separator: "\n")
    }
}
