# Scheduled Review

Scheduled Review is the first phase served by the Learn screen. It contains:

- **New words** (never reviewed).
- **Due words** (`nextReviewAt <= now`).

Only when this set is empty does the app fall through to [Free Review](free-review.md) and show the `Free Review` badge.

## Intervals

`level` is an integer in `0...9`. The interval to the next scheduled review depends on the level:

```
level 0 = 0 days       (immediately due)
level 1 = 1 day
level 2 = 2 days
level 3 = 4 days
level 4 = 7 days
level 5 = 14 days
level 6 = 14 days
level 7 = 14 days
level 8 = 14 days
level 9 = 14 days
```

A word at level 0 is always due — there is no waiting room for brand-new words.

## State updates

**Correct answer:**

```
level         = min(9, level + 1)
nextReviewAt  = now + intervalDays[level]
correctCount += 1
lastReviewedAt = now
```

**Wrong answer:**

```
level         = max(0, level - 1)
nextReviewAt  = now + intervalDays[level]
wrongCount   += 1
lastReviewedAt = now
```

A word that drops to level 0 becomes due immediately because the level-0 interval is 0 days.

## Direction

Direction is updated on every shown card (Scheduled or Free):

```
if lastDirection == nil:
    pick random 50/50
else:
    pick the opposite of lastDirection
lastDirection = shownDirection
lastSeenAt    = now
```

## Required tests

The scheduling test suite must cover:

- Level clamping at both ends (`0` and `9`).
- `nextReviewAt` calculation for every level, including drop-to-zero.
- `correctCount` / `wrongCount` increments.
- `lastSeenAt` / `lastReviewedAt` updates.
- Direction alternation and seeded first-direction determinism.

See [testing.md](testing.md) for the full list.
