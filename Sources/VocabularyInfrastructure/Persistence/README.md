# Persistence

SwiftData records are mapped to and from domain models when `VOCABULARY_SWIFTDATA` is enabled. The default Command Line Tools build uses a JSON-backed fallback repository so tests and the app can run without `SwiftDataMacros`.

Keep scheduling decisions out of persistence types.
