# Testing

The project uses [Swift Testing](https://developer.apple.com/documentation/testing) (not XCTest). Tests live in `Tests/VocabularyCoreTests`.

Scheduling logic is the core risk surface, so the suite focuses there. UI is intentionally not unit-tested for MVP.

## Determinism

- Inject the clock (`now: Date`) — never call `Date()` inside scoring or scheduling functions.
- Inject the RNG. Tests use a seeded RNG so jitter, first-direction, and weighted selection are reproducible.

## Required test categories

### Scheduled Review

- Correct answer: `level` clamps at `9`; `nextReviewAt` matches the interval table.
- Wrong answer: `level` clamps at `0`; a drop to `0` makes the word immediately due.
- `correctCount` / `wrongCount` increment on the right event.
- `lastAnswerWasWrong` toggles to `true` on wrong, `false` on correct.
- `lastReviewedAt` is set on every answer.

### Free Review side effects

- Correct does not change `level`.
- Correct does not change `nextReviewAt`.
- Wrong does not change `level`.
- Wrong does not change `nextReviewAt`.
- Correct increments `correctCount` and sets `lastAnswerWasWrong` to `false`.
- Wrong increments `wrongCount` and sets `lastAnswerWasWrong` to `true`.
- Card shown updates `lastSeenAt`.
- Answer updates `lastReviewedAt`.

### Free Review cooldown

- With exactly 10 words, no duplicate appears in any sliding 10-card window.
- With 1 word, repeated selection is allowed (no other option).
- With fewer than 10 words, immediate repeats are avoided when possible.

### Free Review scoring

- Lower `level` produces a higher weight when other inputs are held equal.
- Older `lastSeenAt` produces a higher weight when other inputs are held equal.
- A word with `lastAnswerWasWrong == true` weighs exactly 5× an otherwise-identical word with `lastAnswerWasWrong == false`.
- Under seeded RNG, jitter stays within `0.85…1.15`.

### Direction

- First direction under seeded RNG is deterministic.
- Direction alternates after the first show.
- Direction does not create separate logical cards.

### Batch behavior

- Refill triggers below threshold; above threshold it does not.
- A generated batch respects the virtual cooldown internally.
- Across many refills, every word remains reachable.

### Performance

- Generating a batch of 50 from 10,000 in-memory words stays within an acceptable local budget.
- The picker has no persistence dependency — assert this structurally, not just by behavior.

### Dictionary parsing & formatting

These tests run on captured real `DCSCopyTextDefinition` output, not on live system calls — `Tests/VocabularyCoreTests/DictionaryFixtures.swift` holds the strings.

- Pronunciation is extracted from the leading `| … |` only when it does not contain part-of-speech keywords.
- Parser identifies multiple parts of speech in one entry, sub-senses split on ` • `, definition vs. example splits on the first `: `.
- Section headers `DERIVATIVES`, `ORIGIN`, `PHRASES`, `USAGE`, `NOTE` separate top-level extras.
- Unstructured input falls back to a single sense with the whole text.
- Formatter respects each toggle independently and never produces double blank lines or leading/trailing whitespace.
- Fallback path: an entry with no parsed senses but with raw text emits normalised whitespace, not empty output.

## Running

```bash
swift test
```

See [build-and-run.md](build-and-run.md) for build paths.
