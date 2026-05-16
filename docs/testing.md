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
- `lastReviewedAt` is set on every answer.

### Free Review side effects

- Correct does not change `level`.
- Correct does not change `nextReviewAt`.
- Wrong does not change `level`.
- Wrong does not change `nextReviewAt`.
- Correct increments `correctCount`.
- Wrong increments `wrongCount`.
- Card shown updates `lastSeenAt`.
- Answer updates `lastReviewedAt`.

### Free Review cooldown

- With exactly 10 words, no duplicate appears in any sliding 10-card window.
- With 1 word, repeated selection is allowed (no other option).
- With fewer than 10 words, immediate repeats are avoided when possible.

### Free Review scoring

- Lower `level` produces a higher weight when other inputs are held equal.
- Older `lastSeenAt` produces a higher weight when other inputs are held equal.
- Higher wrong rate produces a higher weight when other inputs are held equal.
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

## Running

```bash
swift test
```

See [build-and-run.md](build-and-run.md) for build paths.
