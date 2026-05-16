# Add Word

Add Word saves one logical vocabulary card. New words always start at level 0 and are immediately eligible for Scheduled Review.

The Russian field has a trailing translate button that fills the field from the current English value using Apple's `Translation` framework. The button reads English at click time so later edits do not affect the in-flight call; the existing Russian value is overwritten. The view owns the `TranslationSession` via `.translationTask`; the view model holds the configuration and a small `idle / translating / failed` state. See [`docs/architecture.md`](../../../../docs/architecture.md#translation) for the adapter layout.
