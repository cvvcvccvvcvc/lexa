# Free Review

Free Review runs after Scheduled Review is empty. It is **infinite**, draws from **all saved words**, and must not change `level` or `nextReviewAt`.

## Invariants

1. Uses all words.
2. **Never** mutates `level` or `nextReviewAt`.
3. May update `correctCount`, `wrongCount`, `lastAnswerWasWrong`, `lastSeenAt`, `lastReviewedAt`, `lastDirection`.
4. Low-level words appear more often than high-level words.
5. Words not seen for longer appear more often.
6. A word whose most recent answer (in any review mode) was wrong gets a flat 5× priority boost until it is answered correctly again.
7. Order must feel unpredictable.
8. With ≥10 words, no word repeats inside any 10-card sliding window.
9. Must remain smooth with 10,000 in-memory words.
10. The picker reads in-memory words only. No persistence queries inside scoring.

## Cooldown: last 9, not last 10

Block the **last 9** shown IDs:

```swift
recentWindow = min(9, max(0, words.count - 1))
```

With exactly 10 words, blocking 10 leaves zero candidates. Blocking 9 still guarantees that no word repeats within any 10-card window, and gracefully degrades for decks smaller than 10.

## Batch picker

Do not pick from scratch on every Learn render. Maintain a queue:

```
batchSize        = 20
refillThreshold  = 5
recentWindow     = min(9, max(0, words.count - 1))
```

A smaller batch is intentional: a wrong-answer boost on `lastAnswerWasWrong` only takes effect at the next refill, so refilling more often (every ~15 picks) shortens the lag before a freshly-missed word reappears.

Flow:

1. Learn asks the picker for the next word.
2. Picker pops from the in-memory queue.
3. If the queue length drops below `refillThreshold`, refill.
4. Refill scans all words, excludes the cooldown set, and does weighted random selection.
5. During a refill, keep a **virtual** cooldown buffer and a **virtual** `lastSeenAt` for IDs already selected in this batch — so the freshly generated batch does not violate the rules internally.

## Weight formula

```
days       = daysSince(lastSeenAt)           // 30 if lastSeenAt == nil
levelBoost = 1.0 + 0.35 * (9 - level)
ageBoost   = 1.0 + log2(1.0 + days)
errorBoost = lastAnswerWasWrong ? 5.0 : 1.0
jitter     = random(0.85 ... 1.15)

weight     = levelBoost * ageBoost * errorBoost * jitter
```

### Why these shapes

- **`levelBoost`** spans `1.00` (level 9) → `4.15` (level 0). Weak words are clearly favored but strong words are never starved.
- **`ageBoost`** is logarithmic, not linear. Linear age would dominate the score: a 365-day-old word would outweigh everything. Log keeps the contribution bounded (`365 days ≈ 9.52`).
- **`errorBoost`** is a binary 5× flat boost on the most recent answer. A ratio over `wrongCount` / `correctCount` is easily skewed by old history; the binary form responds only to the latest answer and resets the moment the user gets the word right. Five is large enough to dominate the cooldown gap (~9 picks): the wrong word almost always reappears inside the next batch.
- **`jitter`** is narrow (`0.85…1.15`) so order feels unpredictable without making the algorithm noisy.

## Side effects on answer

| Event | `level` | `nextReviewAt` | `correctCount` | `wrongCount` | `lastAnswerWasWrong` | `lastSeenAt` | `lastReviewedAt` | `lastDirection` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Card shown | — | — | — | — | — | now | — | shown |
| Correct | — | — | +1 | — | false | — | now | — |
| Wrong | — | — | — | +1 | true | — | now | — |

The `—` columns are explicitly forbidden from changing. Scheduled Review applies the same `lastAnswerWasWrong` toggle (in addition to its level/nextReviewAt updates) — the flag tracks the latest answer in any mode.

## Not implemented for MVP

FSRS, alias method, Fenwick tree, segment tree, priority queue, duplicated weighted bag. Reconsider only if profiling shows the linear-scan batch refill is visible in the UI, or word count is well past 50,000.

## Reference pseudocode

```swift
func daysSince(_ date: Date?, now: Date) -> Double {
    guard let date else { return 30.0 }
    return max(0, now.timeIntervalSince(date)) / 86_400.0
}

func freeReviewWeight(word: Word, now: Date, rng: inout RNG) -> Double {
    let days        = daysSince(word.lastSeenAt, now: now)
    let levelBoost  = 1.0 + 0.35 * Double(9 - word.level)
    let ageBoost    = 1.0 + log2(1.0 + days)
    let errorBoost: Double = word.lastAnswerWasWrong ? 5.0 : 1.0
    let jitter      = rng.nextDouble(in: 0.85...1.15)
    return max(0.0001, levelBoost * ageBoost * errorBoost * jitter)
}
```

See [testing.md](testing.md) for the full list of required Free Review tests.
