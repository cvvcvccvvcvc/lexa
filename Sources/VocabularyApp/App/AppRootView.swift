import SwiftUI
import VocabularyCore
import VocabularyInfrastructure

#if VOCABULARY_SWIFTDATA
import SwiftData
#endif

enum SidebarSection: String, CaseIterable, Identifiable {
    case learn
    case addWord
    case words

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .learn:
            "Learn"
        case .addWord:
            "Add Word"
        case .words:
            "Words"
        }
    }

    var systemImage: String {
        switch self {
        case .learn:
            "rectangle.stack"
        case .addWord:
            "plus.circle"
        case .words:
            "text.book.closed"
        }
    }
}

struct AppRootView: View {
    #if VOCABULARY_SWIFTDATA
    @Environment(\.modelContext) private var modelContext
    #endif

    @State private var selection: SidebarSection = .learn
    @AppStorage(Lexa.darkModeDefaultsKey) private var isDarkMode = false
    @AppStorage("lexa.sidebar.isVisible") private var isSidebarVisible = true

    private var repository: WordRepository {
        #if VOCABULARY_SWIFTDATA
        WordRepository(modelContext: modelContext)
        #else
        WordRepository.shared
        #endif
    }

    var body: some View {
        HStack(spacing: 0) {
            LexaSidebar(selection: $selection)
                .padding(.leading, isSidebarVisible ? 0 : -Lexa.sidebarWidth)

            VStack(spacing: 0) {
                LexaToolbar(
                    title: selection.title,
                    left: AnyView(sidebarToggleButton),
                    right: AnyView(themeToggleButton)
                )

                Group {
                    switch selection {
                    case .learn:
                        LearnView(repository: repository)
                    case .addWord:
                        AddWordView(
                            repository: repository,
                            jumpToWords: {
                                selection = .words
                            }
                        )
                    case .words:
                        WordsView(repository: repository)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Lexa.windowBackground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipped()
        .background(Lexa.windowBackground)
        .frame(minWidth: 980, minHeight: 640)
        .ignoresSafeArea(.container, edges: .top)
        .animation(.easeInOut(duration: 0.22), value: isSidebarVisible)
        .onAppear {
            Lexa.applyAppearance(isDarkMode: isDarkMode)
        }
        .onChange(of: isDarkMode) { _, newValue in
            Lexa.applyAppearance(isDarkMode: newValue)
        }
        .background(shortcutButtons)
    }

    private var themeToggleButton: some View {
        LexaIconButton(
            title: isDarkMode ? "Switch to light theme" : "Switch to dark theme",
            systemImage: isDarkMode ? "sun.max" : "moon"
        ) {
            isDarkMode.toggle()
        }
    }

    private var sidebarToggleButton: some View {
        LexaIconButton(
            title: isSidebarVisible ? "Hide sidebar" : "Show sidebar",
            systemImage: "sidebar.leading"
        ) {
            isSidebarVisible.toggle()
        }
    }

    private var shortcutButtons: some View {
        Group {
            Button("Next Section") {
                moveSelection(1)
            }
            .keyboardShortcut(.downArrow, modifiers: [.command])
            .opacity(0)
            .accessibilityHidden(true)

            Button("Previous Section") {
                moveSelection(-1)
            }
            .keyboardShortcut(.upArrow, modifiers: [.command])
            .opacity(0)
            .accessibilityHidden(true)

            Button("Toggle Sidebar") {
                isSidebarVisible.toggle()
            }
            .keyboardShortcut("b", modifiers: [.command])
            .opacity(0)
            .accessibilityHidden(true)
        }
        .frame(width: 0, height: 0)
    }

    private func moveSelection(_ delta: Int) {
        let sections = SidebarSection.allCases

        guard let index = sections.firstIndex(of: selection) else {
            selection = .learn
            return
        }

        let nextIndex = min(sections.count - 1, max(0, index + delta))
        selection = sections[nextIndex]
    }
}
