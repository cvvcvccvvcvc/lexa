import SwiftUI
import VocabularyCore
import VocabularyInfrastructure

#if VOCABULARY_SWIFTDATA
import SwiftData
#endif

@main
struct VocabularyTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        #if VOCABULARY_SWIFTDATA
        WindowGroup {
            AppRootView()
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(for: WordRecord.self)
        #else
        WindowGroup {
            AppRootView()
        }
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
