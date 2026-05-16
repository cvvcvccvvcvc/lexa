import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        Task { @MainActor in
            Lexa.applyAppearance(isDarkMode: UserDefaults.standard.bool(forKey: Lexa.darkModeDefaultsKey))
            self.configureWindows()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        configureWindows()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            sender.windows.first?.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    @MainActor
    private func configureWindows() {
        for window in NSApp.windows {
            window.title = ""
            window.toolbar = nil
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.minSize = NSSize(width: 980, height: 640)
        }
    }
}
