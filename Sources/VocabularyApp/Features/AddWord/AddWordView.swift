import AppKit
import SwiftUI
import Translation
import VocabularyCore
import VocabularyInfrastructure

struct AddWordView: View {
    let repository: WordRepository
    var onWordsChanged: () -> Void = {}
    var jumpToWords: () -> Void = {}

    @StateObject private var viewModel = AddWordViewModel()
    @State private var commentHeight = Self.minimumCommentHeight
    @FocusState private var focusedField: Field?

    private static let minimumCommentHeight: CGFloat = 66
    private static let maximumCommentHeight: CGFloat = 220
    private static let reservedVerticalSpace: CGFloat = 330

    private enum Field {
        case english
        case russian
        case comment
    }

    var body: some View {
        GeometryReader { proxy in
            let maxCommentHeight = maxCommentHeight(for: proxy.size.height)

            ZStack(alignment: .bottom) {
                Lexa.windowBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    form(maxCommentHeight: maxCommentHeight)
                        .frame(width: 520)
                        .padding(.top, 40)

                    Spacer()
                }

                if let lastAddedEnglish = viewModel.lastAddedEnglish {
                    LexaToast(word: lastAddedEnglish, actionTitle: "View") {
                        jumpToWords()
                    }
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: maxCommentHeight) { _, newValue in
                commentHeight = min(max(commentHeight, Self.minimumCommentHeight), newValue)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.lastAddedEnglish)
        .onAppear {
            focusedField = .english
        }
        .task(id: viewModel.lastAddedEnglish) {
            guard viewModel.lastAddedEnglish != nil else {
                return
            }

            try? await Task.sleep(for: .seconds(3))
            viewModel.lastAddedEnglish = nil
        }
        .translationTask(viewModel.translationConfiguration) { session in
            await viewModel.runTranslation(using: session)
        }
    }

    private func form(maxCommentHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add a new word")
                .font(.lexaSerif(size: 28, weight: .medium))
                .foregroundStyle(Lexa.text)

            VStack(alignment: .leading, spacing: 6) {
                LexaFieldLabel(title: "English word or phrase")

                TextField("", text: $viewModel.englishText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Lexa.text)
                    .focused($focusedField, equals: .english)
                    .padding(.horizontal, 11)
                    .frame(height: 32)
                    .background(Lexa.inputBackground, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(alignment: .leading) {
                        if viewModel.englishText.isEmpty {
                            Text("e.g. serendipity")
                                .font(.system(size: 14))
                                .foregroundStyle(Lexa.tertiaryText)
                                .padding(.horizontal, 11)
                                .allowsHitTesting(false)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(viewModel.englishError == nil ? Lexa.inputBorder : Lexa.red)
                    }
                    .onChange(of: viewModel.englishText) { _, _ in
                        viewModel.englishError = nil
                        viewModel.dismissTranslationError()
                    }

                if let englishError = viewModel.englishError {
                    Text(englishError)
                        .font(.system(size: 12))
                        .foregroundStyle(Lexa.red)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                LexaFieldLabel(title: "Russian translation")

                TextField("", text: $viewModel.russianTranslation)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Lexa.text)
                    .focused($focusedField, equals: .russian)
                    .padding(.leading, 11)
                    .padding(.trailing, 40)
                    .frame(height: 32)
                    .background(Lexa.inputBackground, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(alignment: .leading) {
                        if viewModel.russianTranslation.isEmpty {
                            Text("например, счастливая случайность")
                                .font(.system(size: 14))
                                .foregroundStyle(Lexa.tertiaryText)
                                .padding(.leading, 11)
                                .allowsHitTesting(false)
                        }
                    }
                    .overlay(alignment: .trailing) {
                        translateButton
                            .padding(.trailing, 4)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(translationErrorVisible || viewModel.russianError != nil ? Lexa.red : Lexa.inputBorder)
                    }
                    .onChange(of: viewModel.russianTranslation) { _, _ in
                        viewModel.russianError = nil
                        viewModel.dismissTranslationError()
                    }

                if let russianError = viewModel.russianError {
                    Text(russianError)
                        .font(.system(size: 12))
                        .foregroundStyle(Lexa.red)
                } else if case .failed(let message) = viewModel.translationState {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(Lexa.red)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                LexaFieldLabel(title: "Comment", optional: true)

                commentEditor(maxHeight: maxCommentHeight)
            }

            HStack(spacing: 8) {
                Spacer()

                LexaSecondaryButton(
                    title: "Clear",
                    isDisabled: viewModel.englishText.isEmpty && viewModel.russianTranslation.isEmpty && viewModel.comment.isEmpty
                ) {
                    viewModel.clear()
                    commentHeight = Self.minimumCommentHeight
                    focusedField = .english
                }

                LexaPrimaryButton(title: "Add Word", isDisabled: !viewModel.canSave) {
                    submit()
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
            .padding(.top, 4)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Lexa.red)
            }
        }
    }

    private var translateButton: some View {
        Button {
            viewModel.requestTranslation()
        } label: {
            Group {
                if viewModel.translationState == .translating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "character.bubble")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .foregroundStyle(viewModel.canTranslate ? Lexa.secondaryText : Lexa.tertiaryText)
            .frame(width: 30, height: 26)
            .contentShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canTranslate)
        .help("Translate English → Russian")
    }

    private var translationErrorVisible: Bool {
        if case .failed = viewModel.translationState {
            return true
        }

        return false
    }

    private func commentEditor(maxHeight: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            if viewModel.comment.isEmpty {
                Text("Memory hook, context, or usage note")
                    .font(.system(size: 13))
                    .foregroundStyle(Lexa.tertiaryText)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
            }

            AutoGrowingCommentEditor(
                text: $viewModel.comment,
                height: $commentHeight,
                minimumHeight: Self.minimumCommentHeight,
                maximumHeight: maxHeight
            )
                .frame(height: commentHeight)
                .background(Color.clear)
        }
        .frame(height: commentHeight)
        .background(Lexa.inputBackground, in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Lexa.inputBorder)
        }
    }

    private func maxCommentHeight(for availableHeight: CGFloat) -> CGFloat {
        let windowLimitedHeight = availableHeight - Self.reservedVerticalSpace
        return min(Self.maximumCommentHeight, max(Self.minimumCommentHeight, windowLimitedHeight))
    }

    private func submit() {
        viewModel.addWord(repository: repository)

        if viewModel.lastAddedEnglish != nil {
            onWordsChanged()
            commentHeight = Self.minimumCommentHeight
            focusedField = .english
        }
    }
}

@MainActor
private struct AutoGrowingCommentEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    let minimumHeight: CGFloat
    let maximumHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.verticalScrollElasticity = .none

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = .systemFont(ofSize: 13)
        textView.textColor = .labelColor
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 11, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)

        scrollView.documentView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView

        Task { @MainActor [coordinator = context.coordinator] in
            coordinator.recalculateHeight()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.scrollView = scrollView

        if let textView = scrollView.documentView as? NSTextView {
            context.coordinator.textView = textView
            textView.font = .systemFont(ofSize: 13)
            textView.textColor = .labelColor

            if textView.string != text {
                textView.string = text
            }
        }

        Task { @MainActor [coordinator = context.coordinator] in
            coordinator.recalculateHeight()
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AutoGrowingCommentEditor
        weak var scrollView: NSScrollView?
        weak var textView: NSTextView?

        init(_ parent: AutoGrowingCommentEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else {
                return
            }

            if parent.text != textView.string {
                parent.text = textView.string
            }

            recalculateHeight()
            textView.scrollRangeToVisible(textView.selectedRange())
        }

        func recalculateHeight() {
            guard let scrollView, let textView, let textContainer = textView.textContainer, let layoutManager = textView.layoutManager else {
                return
            }

            let contentWidth = max(scrollView.contentSize.width, 1)
            textContainer.containerSize = NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
            layoutManager.ensureLayout(for: textContainer)

            let usedRect = layoutManager.usedRect(for: textContainer)
            let contentHeight = ceil(usedRect.height + textView.textContainerInset.height * 2)
            let nextHeight = min(max(contentHeight, parent.minimumHeight), parent.maximumHeight)
            let shouldScroll = contentHeight > parent.maximumHeight + 0.5

            scrollView.hasVerticalScroller = shouldScroll
            scrollView.verticalScrollElasticity = shouldScroll ? .automatic : .none

            var textFrame = textView.frame
            textFrame.size.width = contentWidth
            textFrame.size.height = max(contentHeight, nextHeight)
            textView.frame = textFrame

            if abs(parent.height - nextHeight) > 0.5 {
                parent.height = nextHeight
            }
        }
    }
}
