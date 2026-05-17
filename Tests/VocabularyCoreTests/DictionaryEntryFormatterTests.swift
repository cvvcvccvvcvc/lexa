import Foundation
import Testing
@testable import VocabularyCore

@Suite("Dictionary Entry Formatter")
struct DictionaryEntryFormatterTests {
    @Test("default output has definitions and examples but no pronunciation or extras")
    func defaultOptions() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.ephemeral)
        let output = DictionaryEntryFormatter.format(entry, options: .default)

        #expect(output.contains("adjective — lasting for a very short time"))
        #expect(output.contains("e.g. fashions are ephemeral"))
        #expect(output.contains("• "))
        #expect(!output.contains("ɪˈfɛm"))
        #expect(!output.contains("Origin:"))
        #expect(!output.contains("Derivatives:"))
    }

    @Test("includePronunciation prepends the pronunciation as its own line")
    func includePronunciation() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.ephemeral)
        let output = DictionaryEntryFormatter.format(
            entry,
            options: DictionaryFormattingOptions(
                includePronunciation: true,
                includeExamples: true,
                includeExtras: false
            )
        )

        #expect(output.hasPrefix("ɪˈfɛm"))
    }

    @Test("excluding examples removes the e.g. lines")
    func excludeExamples() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.ephemeral)
        let output = DictionaryEntryFormatter.format(
            entry,
            options: DictionaryFormattingOptions(
                includePronunciation: false,
                includeExamples: false,
                includeExtras: false
            )
        )

        #expect(!output.contains("e.g."))
        #expect(!output.contains("fashions are ephemeral"))
        #expect(output.contains("adjective — lasting for a very short time"))
    }

    @Test("includeExtras appends Origin and Derivatives blocks")
    func includeExtras() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.ephemeral)
        let output = DictionaryEntryFormatter.format(
            entry,
            options: DictionaryFormattingOptions(
                includePronunciation: false,
                includeExamples: true,
                includeExtras: true
            )
        )

        #expect(output.contains("Origin:"))
        #expect(output.contains("Derivatives:"))
        #expect(output.contains("Greek"))
    }

    @Test("output has no leading or trailing blank lines and no double blanks")
    func collapsesBlankLines() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.cat)
        let output = DictionaryEntryFormatter.format(
            entry,
            options: DictionaryFormattingOptions(
                includePronunciation: true,
                includeExamples: true,
                includeExtras: true
            )
        )

        #expect(!output.hasPrefix("\n"))
        #expect(!output.hasSuffix("\n"))
        #expect(!output.contains("\n\n\n"))
    }

    @Test("falls back to normalized raw text when no senses parsed")
    func fallbackOnUnstructured() {
        let entry = DictionaryEntry(raw: "stray text   with    spaces")
        let output = DictionaryEntryFormatter.format(entry, options: .default)

        #expect(output == "stray text with spaces")
    }

    @Test("empty entry produces empty output")
    func emptyEntry() {
        let entry = DictionaryEntry()
        let output = DictionaryEntryFormatter.format(entry, options: .default)

        #expect(output.isEmpty)
    }
}
