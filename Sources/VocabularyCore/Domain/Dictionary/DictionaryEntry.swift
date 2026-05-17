import Foundation

public struct DictionaryEntry: Equatable {
    public var pronunciation: String?
    public var senses: [Sense]
    public var origin: String?
    public var phrases: String?
    public var derivatives: String?
    public var usage: String?
    public var note: String?
    public var raw: String

    public init(
        pronunciation: String? = nil,
        senses: [Sense] = [],
        origin: String? = nil,
        phrases: String? = nil,
        derivatives: String? = nil,
        usage: String? = nil,
        note: String? = nil,
        raw: String = ""
    ) {
        self.pronunciation = pronunciation
        self.senses = senses
        self.origin = origin
        self.phrases = phrases
        self.derivatives = derivatives
        self.usage = usage
        self.note = note
        self.raw = raw
    }
}

extension DictionaryEntry {
    public struct Sense: Equatable {
        public var partOfSpeech: String?
        public var definition: String
        public var examples: [String]
        public var subSenses: [SubSense]

        public init(
            partOfSpeech: String? = nil,
            definition: String,
            examples: [String] = [],
            subSenses: [SubSense] = []
        ) {
            self.partOfSpeech = partOfSpeech
            self.definition = definition
            self.examples = examples
            self.subSenses = subSenses
        }
    }

    public struct SubSense: Equatable {
        public var definition: String
        public var examples: [String]

        public init(definition: String, examples: [String] = []) {
            self.definition = definition
            self.examples = examples
        }
    }
}

public struct DictionaryFormattingOptions: Equatable, Sendable {
    public var includePronunciation: Bool
    public var includeExamples: Bool
    public var includeExtras: Bool

    public init(
        includePronunciation: Bool = false,
        includeExamples: Bool = true,
        includeExtras: Bool = false
    ) {
        self.includePronunciation = includePronunciation
        self.includeExamples = includeExamples
        self.includeExtras = includeExtras
    }

    public static let `default` = DictionaryFormattingOptions()
}
