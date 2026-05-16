# Agent Workflow

This document defines how AI coding agents work on this repository. The short form lives in [`AGENTS.md`](../AGENTS.md); this is the long form.

## Operating principles

1. **Read before you write.** Open the files you are about to change. Open the module README next to them. Open the relevant `docs/` page only if your task needs that depth.
2. **Keep changes small.** Prefer one focused change per turn over a sweeping refactor. Do not bundle unrelated cleanup into a feature change.
3. **Respect the layer boundaries.** See [architecture.md](architecture.md). Domain stays pure. Views stay thin. Persistence stays behind adapters.
4. **Inject the clock and RNG.** Anything in scheduling that depends on time or randomness must accept it as a parameter so tests can be deterministic.

## Implementation loop

1. Restate the task in one or two sentences. Identify the affected target(s).
2. Read the relevant code and module README.
3. Make the change.
4. Run `swift test`.
5. Report changed files, tests run, test result, known limitations.
6. Stop. Do not commit until the user has manually tested and approved.

## Documentation maintenance

**Keep documentation current.** After any change, evaluate whether documentation is now stale. If yes, update it in the same turn — do not defer.

A non-exhaustive checklist of when to update what:

| If you changed… | Update… |
| --- | --- |
| A scheduling interval, formula, or invariant | [scheduled-review.md](scheduled-review.md) or [free-review.md](free-review.md) |
| A persisted field, the model, or the persistence gate | [product.md](product.md#persisted-fields), [architecture.md](architecture.md#persistence-gating) |
| Module boundaries, dependencies, or target layout | [architecture.md](architecture.md), affected module READMEs, `Package.swift` |
| Build commands, scripts, or build flags | [build-and-run.md](build-and-run.md), root [`README.md`](../README.md) |
| A test category or testing tool | [testing.md](testing.md), [`Tests/VocabularyCoreTests/README.md`](../Tests/VocabularyCoreTests/README.md) |
| A product rule, UI section, or copy that users see | [product.md](product.md) |
| A globally-applicable agent rule | [`AGENTS.md`](../AGENTS.md) |

Rules of thumb:

- If a doc and the code now disagree, the doc is wrong. Fix it.
- If a doc names a file, function, or flag that no longer exists, fix or remove the reference.
- Do **not** invent updates when nothing changed semantically. Avoid noise.
- Do **not** turn documentation into a changelog. State the current truth; let `git log` carry history.

## What not to create

- `AI_CHANGELOG.md`, `DECISIONS.md`, or any per-task journal file. Decisions belong in commit messages and PR descriptions.
- Long process logs or "what I just did" summaries inside `docs/`.
- A new top-level doc when a section in an existing doc would do.

## Git policy

- Do not commit automatically.
- Granular commits only — one logical change per commit.
- Commit only after: (1) `swift test` passes, (2) the user has manually tested the app, (3) the user explicitly approves.
- Before proposing a commit, show: changed files, tests run, test result, proposed commit message.

## Subagent policy

Use subagents primarily for inspection and critique, not for parallel writes. Useful reviewer roles:

1. **Scheduling reviewer** — verifies SRS and Free Review logic and edge cases.
2. **macOS UI reviewer** — verifies native navigation choices and screen simplicity.
3. **Persistence reviewer** — verifies adapter boundaries and that scoring never touches storage.
4. **Test reviewer** — finds untested edge cases.
5. **Documentation reviewer** — verifies that `AGENTS.md` stays short, `docs/` stays current, and module READMEs stay useful.

Avoid running multiple agents that edit the same files at the same time.
