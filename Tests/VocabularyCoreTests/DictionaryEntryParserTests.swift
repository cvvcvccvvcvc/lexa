import Foundation
import Testing
@testable import VocabularyCore

@Suite("Dictionary Entry Parser")
struct DictionaryEntryParserTests {
    @Test("extracts pronunciation, senses, derivatives, and origin for a simple word")
    func parsesEphemeral() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.ephemeral)

        #expect(entry.pronunciation == "ɪˈfɛm(ə)r(ə)l, ɛˈfɛm(ə)r(ə)l")
        #expect(entry.senses.count == 2)

        let adjective = entry.senses[0]
        #expect(adjective.partOfSpeech == "adjective")
        #expect(adjective.definition == "lasting for a very short time")
        #expect(adjective.examples.first?.hasPrefix("fashions are ephemeral") == true)
        #expect(adjective.examples.count == 2)
        #expect(adjective.subSenses.count == 1)
        #expect(adjective.subSenses[0].definition.contains("having a very short life cycle"))
        #expect(adjective.subSenses[0].examples.first?.contains("chickweed") == true)

        let noun = entry.senses[1]
        #expect(noun.partOfSpeech == "noun")
        #expect(noun.definition == "an ephemeral plant")

        #expect(entry.derivatives?.contains("ephemerality") == true)
        #expect(entry.origin?.contains("Greek") == true)
        #expect(entry.phrases == nil)
    }

    @Test("parses multi-part-of-speech entry with PHRASES section")
    func parsesCat() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.cat)

        #expect(entry.pronunciation == "kat")
        #expect(entry.senses.count >= 2)
        #expect(entry.senses.contains { $0.partOfSpeech == "noun" })
        #expect(entry.senses.contains { $0.partOfSpeech == "verb" })

        #expect(entry.phrases?.contains("let the cat out of the bag") == true)
        #expect(entry.origin?.contains("Old English") == true)
    }

    @Test("separates definition from examples on the first colon")
    func splitsFirstExample() {
        let entry = DictionaryEntryParser.parse("test | tɛst | noun a thing: a sample sentence.")

        #expect(entry.senses.count == 1)
        #expect(entry.senses[0].definition == "a thing")
        #expect(entry.senses[0].examples == ["a sample sentence."])
    }

    @Test("splits multiple examples on the pipe separator")
    func splitsMultipleExamples() {
        let entry = DictionaryEntryParser.parse("test | tɛst | noun a thing: first example | second example | third example.")

        #expect(entry.senses[0].examples.count == 3)
        #expect(entry.senses[0].examples[0] == "first example")
        #expect(entry.senses[0].examples[2] == "third example.")
    }

    @Test("returns a fallback single sense when no part of speech is detected")
    func parsesUnstructuredText() {
        let entry = DictionaryEntryParser.parse("some opaque text with no markers at all")

        #expect(entry.pronunciation == nil)
        #expect(entry.senses.count == 1)
        #expect(entry.senses[0].partOfSpeech == nil)
        #expect(entry.senses[0].definition.contains("some opaque text"))
    }

    @Test("returns an empty entry for empty input")
    func parsesEmpty() {
        let entry = DictionaryEntryParser.parse("")

        #expect(entry.pronunciation == nil)
        #expect(entry.senses.isEmpty)
    }

    @Test("rejects a pronunciation candidate that looks like an example separator")
    func rejectsExampleAsPronunciation() {
        let entry = DictionaryEntryParser.parse("phrase noun something happened | she said something.")

        #expect(entry.pronunciation == nil)
    }

    @Test("ignores part-of-speech keywords inside square brackets")
    func ignoresBracketedPartOfSpeech() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.dog)

        let parts = entry.senses.map(\.partOfSpeech)
        #expect(parts == ["noun", "verb"])
        #expect(entry.senses.contains { $0.subSenses.contains { $0.definition.contains("[with adjective]") } })
    }

    @Test("recognises the PHRASAL VERBS section header")
    func parsesPhrasalVerbsSection() {
        let entry = DictionaryEntryParser.parse(DictionaryFixtures.dog)

        #expect(entry.phrases?.contains("dog eat dog") == true)
        #expect(entry.origin?.contains("Old English") == true)
    }
}
