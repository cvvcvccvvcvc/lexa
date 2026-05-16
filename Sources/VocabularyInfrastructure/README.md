# Infrastructure

Infrastructure adapts system frameworks to the app:

- SwiftData for local persistence when `VOCABULARY_SWIFTDATA` is defined with a full Xcode SDK.
- JSON persistence fallback for the default Command Line Tools build in this workspace.
- AVFoundation speech synthesis behind a small service protocol.

Infrastructure may depend on domain models. Domain code must not depend on infrastructure.
