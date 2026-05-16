# Scheduling

Scheduling owns Scheduled Review, Free Review scoring, weighted selection, recent protection, and deterministic random generation.

The Free Review picker works from in-memory words only. It does not fetch from SwiftData or mutate persistence records directly.
