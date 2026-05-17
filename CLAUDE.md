# AGENTS.md

Short, always-loaded guide for AI agents working on this repo. Deeper material lives in [`docs/`](docs/README.md) and module READMEs — load those on demand.

## What this project is

Lexa is a native, local-first macOS vocabulary trainer. The user saves English words with Russian translations and reviews them through Scheduled Review first, then infinite Free Review. macOS 15+, Swift 6, SwiftUI, Swift Testing.

## Repository map

- `Sources/VocabularyCore/` — pure domain models and review algorithms.
- `Sources/VocabularyInfrastructure/` — persistence (SwiftData + JSON fallback) and speech adapters.
- `Sources/VocabularyApp/` — application composition and SwiftUI feature screens.
- `Tests/VocabularyCoreTests/` — Swift Testing suite for the domain layer.
- `Scripts/build-app.sh` — packages a SwiftPM executable as a macOS `.app`.
- `docs/` — long-form documentation (architecture, algorithms, workflow).

## Build / test

```bash
swift build               # default: JSON fallback persistence
swift test                # run the test suite
swift run VocabularyApp   # quick dev run
./Scripts/build-app.sh    # produce Build/Lexa.app
```

SwiftData adapter path (needs a full Xcode SDK with `SwiftDataMacros`):

```bash
swift run -Xswiftc -DVOCABULARY_SWIFTDATA VocabularyApp
```

Why two paths: see [docs/architecture.md](docs/architecture.md#persistence-gating).

## Universal rules

1. **Layering.** Domain stays pure: no SwiftUI, SwiftData, or AVFoundation imports in `VocabularyCore`. Views stay thin. Persistence stays behind adapters.
2. **Pure scheduling.** Inject the clock and RNG into scheduling functions. Never call `Date()` or unseeded randomness inside scoring.
3. **No persistence in scoring.** Free Review picker reads in-memory words only.
4. **One word = one card.** Direction alternates per word; do not create separate EN→RU and RU→EN entities.
5. **Levels** are integers `0…9`. New words start at `0`. Free Review must not change `level` or `nextReviewAt`.
6. **Tests are Swift Testing.** Scheduling tests are mandatory; UI is not unit-tested for MVP.
7. **Git.** Do not commit automatically. Commit only after tests pass, the user has manually tested, and the user has explicitly approved.
8. **Minimal but sufficient changes.** Make the smallest edit that achieves the goal — no incidental refactors, no unrelated rewrites, no new abstractions "just in case." Prefer idiomatic Swift / SwiftUI / AppKit APIs and platform conventions over custom mechanisms. If a native API solves the problem, use it instead of reinventing it.

## Documentation policy

**Keep documentation current.** After any change, decide whether docs are now stale; if yes, update them in the same turn. Do not defer doc updates to a follow-up commit.

Quick map of what to update when:

| If you changed… | Update… |
| --- | --- |
| Scheduling interval / formula / invariant | [docs/scheduled-review.md](docs/scheduled-review.md) or [docs/free-review.md](docs/free-review.md) |
| Persisted field, model, persistence gate | [docs/product.md](docs/product.md), [docs/architecture.md](docs/architecture.md) |
| Module boundaries, targets, dependencies | [docs/architecture.md](docs/architecture.md) + affected module READMEs + `Package.swift` |
| Build commands or scripts | [docs/build-and-run.md](docs/build-and-run.md), [`README.md`](README.md) |
| Test policy or coverage area | [docs/testing.md](docs/testing.md), [`Tests/VocabularyCoreTests/README.md`](Tests/VocabularyCoreTests/README.md) |
| Product rule / UI section / user-facing copy | [docs/product.md](docs/product.md) |
| A globally-applicable agent rule | this file |

If a doc and the code disagree, the doc is wrong — fix it. If a doc names a file, function, or flag that no longer exists, fix the reference. Do **not** invent updates when nothing changed semantically; do **not** turn docs into a changelog. The full doc-maintenance protocol is in [docs/agent-workflow.md](docs/agent-workflow.md#documentation-maintenance).

Do **not** create `AI_CHANGELOG.md`, `DECISIONS.md`, or per-task journal files.

## Where to look next

- New to the product? → [docs/product.md](docs/product.md)
- Touching the algorithm? → [docs/scheduled-review.md](docs/scheduled-review.md), [docs/free-review.md](docs/free-review.md)
- Working in a specific module? → the local `README.md` next to the code.
- Working on tests? → [docs/testing.md](docs/testing.md)
- Anything about workflow, subagents, or git? → [docs/agent-workflow.md](docs/agent-workflow.md)
