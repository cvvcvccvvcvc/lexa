# Translation

On-device English → Russian translation through Apple's `Translation` framework. Used by Add Word to auto-fill the Russian field.

`AppleTranslationService.translate(_:using:)` is a thin wrapper around `TranslationSession.translate` that trims input, surfaces a typed `TranslationError`, and re-throws `CancellationError` unchanged so SwiftUI task cancellation does not look like a user-facing failure.

The `TranslationSession` itself is owned by the SwiftUI view via the `.translationTask` modifier and passed in per call. Feature code does not hold a long-lived session.
