# Dictionary

`AppleDictionaryService.lookup(_:)` wraps `DCSCopyTextDefinition` from `CoreServices`. It does not parse — the returned plain text goes to `DictionaryEntryParser` in [`VocabularyCore/Domain/Dictionary`](../../VocabularyCore/Domain/Dictionary/README.md).

Lookups query whichever dictionaries the user has enabled in System Settings → Dictionary, in their configured priority order. We have no control over that selection, by design; if a user's primary dictionary returns Russian definitions for an English word that is what we hand back to the formatter.

A nil result from `DCSCopyTextDefinition` (or an empty trimmed string) surfaces as `DictionaryLookupError.notFound`.
