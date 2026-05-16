# Product

Lexa is a local-first macOS vocabulary trainer. The user saves English words with Russian translations and reviews them through a two-phase loop: Scheduled Review first, then infinite Free Review.

## MVP boundaries

In scope:

- Native macOS SwiftUI app, macOS 14+.
- Local data only. No backend, no account, no sync, no import/export.
- Three sidebar sections: **Learn**, **Add Word**, **Words**.
- English pronunciation via Apple speech synthesis behind a service abstraction.

Out of scope for MVP: Settings screen, tags, decks, statistics dashboard, FSRS, full Anki parity.

## Navigation

Use macOS-native `NavigationSplitView` with a sidebar and detail area. Do not use mobile-style bottom tabs.

## Sections

### Learn

Main screen. Shows one card at a time.

- If no words exist, show an empty state asking the user to add a word.
- Card shows either the English or Russian side first. Tapping the card or pressing Space reveals the answer plus the optional comment and the **Wrong** / **Correct** buttons.
- After an answer, the next card appears immediately.
- A speaker button pronounces the English side.
- When the queue enters Free Review, show a small `Free Review` badge.

### Add Word

Manual word entry. Fields:

- English word or phrase (required).
- Russian translation (required).
- Comment (optional — synonyms, usage notes, examples, nuance).

After save: persist the word, clear the form, stay on Add Word, show a lightweight confirmation. The user never sees technical fields.

### Words

Library / management view. Lists saved words with `English`, `Russian`, and `Level`. Opening a word allows editing the three user-facing fields or deleting it (with confirmation). Internal scheduling fields are hidden.

## Card model

One saved word is **one logical card**. Do not create separate EN→RU and RU→EN cards.

Direction is stored per word:

- First show: random 50/50.
- Every subsequent show: opposite of `lastDirection`.

## Levels

Each word has a single integer `level` in `0...9`. New words start at `0`. Level is progress, not a rating — render it as `Level N`, never as stars.

## Review phases

Learn always serves Scheduled Review first. Free Review only starts when no new or due words remain. See [scheduled-review.md](scheduled-review.md) and [free-review.md](free-review.md) for the algorithms.

## Persisted fields

At minimum: `id`, `englishText`, `russianTranslation`, `comment`, `level`, `createdAt`, `updatedAt`, `nextReviewAt`, `lastSeenAt`, `lastReviewedAt`, `lastDirection`, `correctCount`, `wrongCount`.
