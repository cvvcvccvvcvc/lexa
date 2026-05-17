# Documentation Index

This folder is the long-form reference for the project. The root [`AGENTS.md`](../AGENTS.md) is the short, always-loaded entry point for AI agents; it links here when an agent needs more depth on a specific topic.

Read only what your current task needs. Each document is self-contained.

## Map

| Document | When to read it |
| --- | --- |
| [product.md](product.md) | Product scope, MVP boundaries, UI sections, user-facing rules. |
| [architecture.md](architecture.md) | Layering, module boundaries, dependency rules, persistence gating. |
| [scheduled-review.md](scheduled-review.md) | Scheduled Review intervals, level transitions, due logic. |
| [free-review.md](free-review.md) | Free Review picker, weight formula, cooldown, batch refill. |
| [build-and-run.md](build-and-run.md) | Build commands, `VOCABULARY_SWIFTDATA` gate, app bundle script. |
| [testing.md](testing.md) | Testing policy, required scheduling test categories, RNG seeding. |
| [agent-workflow.md](agent-workflow.md) | Agent workflow, doc maintenance, git policy, subagent guidance. |

## Module-level docs

Module-specific invariants live next to the code, not here:

- [`Sources/VocabularyCore/Domain/README.md`](../Sources/VocabularyCore/Domain/README.md)
- [`Sources/VocabularyCore/Domain/Models/README.md`](../Sources/VocabularyCore/Domain/Models/README.md)
- [`Sources/VocabularyCore/Domain/Scheduling/README.md`](../Sources/VocabularyCore/Domain/Scheduling/README.md)
- [`Sources/VocabularyInfrastructure/README.md`](../Sources/VocabularyInfrastructure/README.md)
- [`Sources/VocabularyInfrastructure/Persistence/README.md`](../Sources/VocabularyInfrastructure/Persistence/README.md)
- [`Sources/VocabularyCore/Domain/Dictionary/README.md`](../Sources/VocabularyCore/Domain/Dictionary/README.md)
- [`Sources/VocabularyInfrastructure/Dictionary/README.md`](../Sources/VocabularyInfrastructure/Dictionary/README.md)
- [`Sources/VocabularyInfrastructure/Speech/README.md`](../Sources/VocabularyInfrastructure/Speech/README.md)
- [`Sources/VocabularyInfrastructure/Translation/README.md`](../Sources/VocabularyInfrastructure/Translation/README.md)
- [`Sources/VocabularyApp/App/README.md`](../Sources/VocabularyApp/App/README.md)
- [`Sources/VocabularyApp/Features/README.md`](../Sources/VocabularyApp/Features/README.md)
- [`Sources/VocabularyApp/Features/Learn/README.md`](../Sources/VocabularyApp/Features/Learn/README.md)
- [`Sources/VocabularyApp/Features/AddWord/README.md`](../Sources/VocabularyApp/Features/AddWord/README.md)
- [`Sources/VocabularyApp/Features/Words/README.md`](../Sources/VocabularyApp/Features/Words/README.md)
- [`Tests/VocabularyCoreTests/README.md`](../Tests/VocabularyCoreTests/README.md)
