# Architecture

The project is a Swift Package Manager workspace with three targets layered top-down. Each layer depends only on layers below it.

```
VocabularyApp        ← App composition + SwiftUI feature screens
   │
   ├── VocabularyInfrastructure   ← Persistence + speech adapters
   │
   └── VocabularyCore             ← Pure domain models + scheduling
```

## Targets

- **`VocabularyCore`** (`Sources/VocabularyCore`): pure Swift. Owns domain models and review algorithms. Must not import SwiftUI, SwiftData, AVFoundation, or perform persistence I/O.
- **`VocabularyInfrastructure`** (`Sources/VocabularyInfrastructure`): adapts system frameworks to domain types. Persistence and speech live here.
- **`VocabularyApp`** (`Sources/VocabularyApp`): executable. App composition + SwiftUI features for Learn, Add Word, Words.
- **`VocabularyCoreTests`** (`Tests/VocabularyCoreTests`): Swift Testing suite for the domain layer.

## Hard dependency rules

1. Domain does not import UI or system framework adapters.
2. SwiftUI views do not call AVFoundation or SwiftData directly. They go through services from `VocabularyInfrastructure` and pure types from `VocabularyCore`.
3. Free Review scoring reads only in-memory words. It must not query persistence inside the scoring loop. See [free-review.md](free-review.md).
4. Scheduling logic stays pure. No view-layer state, no `Date()` defaulting inside core functions — inject the clock and RNG so tests are deterministic.

## Persistence gating

The default Command Line Tools build in this workspace does not include `SwiftDataMacros`. To keep the project buildable everywhere, persistence has two implementations behind one repository protocol:

- **JSON fallback** (default): a small JSON-backed repository.
- **SwiftData adapter**: compiled when `VOCABULARY_SWIFTDATA` is defined and a full Xcode SDK is available.

Build commands for both paths are in [build-and-run.md](build-and-run.md). The fallback is not a temporary workaround — it is the supported path for environments without `SwiftDataMacros`.

## Speech

`SpeechService` (protocol) + `AppleSpeechService` (AVFoundation adapter) keep AVFoundation out of feature views. Feature code calls the protocol only.

## Translation

`AppleTranslationService` (in `VocabularyInfrastructure/Translation`) is a nonisolated namespace whose single static method wraps `TranslationSession.translate`. The session itself is owned by the SwiftUI view via the `.translationTask` modifier and passed in per call — there is no long-lived service object, because `TranslationSession` is fundamentally view-scoped.

The Add Word feature holds a `TranslationSession.Configuration` in its view model. Tapping the translate button mutates that configuration (via `invalidate()` on existing or a fresh instance), which triggers `.translationTask` to vend a new session to the view model. The view model captures the English text at click time so later edits do not affect the in-flight translation.

`Translation` is only imported from `VocabularyInfrastructure/Translation/` and the Add Word feature. No other code in the project depends on it.

## Where to put new code

| Kind of change | Target |
| --- | --- |
| New domain rule, algorithm, or invariant | `VocabularyCore` |
| New system framework adapter (file, network, audio…) | `VocabularyInfrastructure` |
| New screen, navigation, or view model | `VocabularyApp` |
| New scheduling test | `Tests/VocabularyCoreTests` |
