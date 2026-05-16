# Build and Run

The project is a Swift Package targeting macOS 14+.

## Prerequisites

- macOS 14 or later.
- Swift 6 toolchain.
- For the SwiftData adapter path: a full Xcode SDK that ships with `SwiftDataMacros`. Plain Command Line Tools do not include it.

## Default build (JSON fallback)

```bash
swift build
swift run VocabularyApp
```

This uses the JSON-backed repository so the package builds on machines without `SwiftDataMacros`. See [architecture.md](architecture.md#persistence-gating) for why both paths exist.

## SwiftData build

```bash
swift run -Xswiftc -DVOCABULARY_SWIFTDATA VocabularyApp
```

Same flag is needed for any other build invocation that should compile the SwiftData adapter.

## Producing a macOS `.app` bundle

A helper script wraps the SwiftPM output in a proper application bundle:

```bash
./Scripts/build-app.sh
open Build/Lexa.app
```

## Tests

```bash
swift test
```

The test target depends only on `VocabularyCore`, so it runs on either persistence path. See [testing.md](testing.md) for what the suite must cover.
