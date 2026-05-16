# Lexa

Native, local-first macOS vocabulary trainer. Save English words with Russian translations and review them through Scheduled Review and infinite Free Review.

## Stack

- Swift 6 / SwiftUI / Swift Testing
- macOS 14+
- SwiftData adapter behind `VOCABULARY_SWIFTDATA`; JSON fallback for environments without `SwiftDataMacros`

## Build and run

```bash
swift build
swift run VocabularyApp
./Scripts/build-app.sh && open Build/Lexa.app
```

SwiftData adapter path:

```bash
swift run -Xswiftc -DVOCABULARY_SWIFTDATA VocabularyApp
```

## Test

```bash
swift test
```

## Documentation

- [`AGENTS.md`](AGENTS.md) — short guide for AI agents, with universal rules and an index of deeper docs.
- [`docs/`](docs/README.md) — long-form documentation: product, architecture, algorithms, build, testing, agent workflow.
- Module READMEs live next to the code they describe.
