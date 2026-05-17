# Dictionary

Pure parsing and formatting for macOS Dictionary lookups. The Infrastructure layer ([`AppleDictionaryService`](../../../VocabularyInfrastructure/Dictionary/README.md)) calls `DCSCopyTextDefinition` and returns raw plain text; everything downstream lives here.

`DCSCopyTextDefinition` returns a single-line stream with no `\n`. Section boundaries are inferred from inline markers:

- Pronunciation: the first ` | … | ` block right after the headword.
- Part of speech: one of `noun`, `verb`, `adjective`, `adverb`, … as a whole-word token.
- Sub-senses: a literal ` • ` separator.
- Definition vs. example: the first `: ` inside a sense unit. Subsequent examples are separated by ` | `.
- Section headers: ALL-CAPS tokens `DERIVATIVES`, `ORIGIN`, `PHRASES`, `USAGE`, `NOTE` with whitespace on both sides.

If none of these markers are present (e.g. a different dictionary with an unfamiliar format), the parser gracefully degrades: senses become a single block containing the whole text, and the formatter normalises whitespace and emits it as-is.

`DictionaryFormattingOptions` selects which slices reach the output: definitions always; pronunciation, examples, and the bundled extras (origin / phrases / derivatives / usage / note) are independently togglable.
