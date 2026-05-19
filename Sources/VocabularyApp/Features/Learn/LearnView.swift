import AppKit
import Carbon.HIToolbox
import SwiftUI
import VocabularyCore
import VocabularyInfrastructure

struct LearnView: View {
    let repository: WordRepository
    var onWordsChanged: () -> Void = {}

    @StateObject private var viewModel: LearnViewModel
    @State private var speakKeyMonitor: Any?

    init(
        repository: WordRepository,
        onWordsChanged: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.onWordsChanged = onWordsChanged
        _viewModel = StateObject(wrappedValue: LearnViewModel(speechService: AppleSpeechService()))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Lexa.windowBackground
                .ignoresSafeArea()

            if let card = viewModel.currentCard {
                cardContent(card)
            } else {
                emptyState
            }

            if viewModel.currentCard != nil {
                modeBadge
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Lexa.red)
                    .padding(.top, 40)
            }
        }
        .task {
            viewModel.load(repository: repository)
        }
        .onAppear { installSpeakMonitor() }
        .onDisappear { removeSpeakMonitor() }
    }

    private func installSpeakMonitor() {
        guard speakKeyMonitor == nil else {
            return
        }

        speakKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == UInt16(kVK_ANSI_S),
                  event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty else {
                return event
            }

            if NSApp.keyWindow?.firstResponder is NSText {
                return event
            }

            guard viewModel.canSpeakCurrentEnglish else {
                return event
            }

            viewModel.speakCurrentEnglish()
            return nil
        }
    }

    private func removeSpeakMonitor() {
        if let monitor = speakKeyMonitor {
            NSEvent.removeMonitor(monitor)
            speakKeyMonitor = nil
        }
    }

    @ViewBuilder
    private var modeBadge: some View {
        if viewModel.isFreeReviewActive {
            HStack(spacing: 6) {
                Circle()
                    .fill(Lexa.tertiaryText)
                    .frame(width: 4, height: 4)

                Text("Free Review")
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(Lexa.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Lexa.badgeBackground, in: Capsule())
        } else if let card = viewModel.currentCard {
            Text("\(viewModel.scheduledDueCount) due · level \(card.word.level)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Lexa.tertiaryText)
                .monospacedDigit()
        }
    }

    private func cardContent(_ card: ReviewCard) -> some View {
        GeometryReader { proxy in
            let cardWidth = cardWidth(for: card, availableWidth: proxy.size.width)
            let cardHeight = cardHeight(for: card, width: cardWidth)
            let center = cardCenterY(cardHeight: cardHeight, availableHeight: proxy.size.height)
            let buttonY = center + cardHeight / 2 + 40

            ZStack(alignment: .top) {
                reviewCard(card, width: cardWidth, height: cardHeight)
                    .position(x: proxy.size.width / 2, y: center)

                if viewModel.isAnswerVisible {
                    HStack(spacing: 12) {
                        judgmentButton(title: "Wrong", systemImage: "xmark", color: Lexa.red, background: Lexa.redBackground) {
                            viewModel.answer(.wrong, repository: repository, onWordsChanged: onWordsChanged)
                        }
                        .keyboardShortcut(.leftArrow, modifiers: [])

                        judgmentButton(title: "Correct", systemImage: "checkmark", color: Lexa.green, background: Lexa.greenBackground) {
                            viewModel.answer(.correct, repository: repository, onWordsChanged: onWordsChanged)
                        }
                        .keyboardShortcut(.rightArrow, modifiers: [])
                    }
                    .position(x: proxy.size.width / 2, y: buttonY)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.18), value: viewModel.isAnswerVisible)
                } else {
                    spaceRevealHint
                        .position(x: proxy.size.width / 2, y: center + cardHeight / 2 + 28)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func cardCenterY(cardHeight: CGFloat, availableHeight: CGFloat) -> CGFloat {
        let badgeBottom: CGFloat = 32
        let cardTopGap: CGFloat = 28
        let bottomGap: CGFloat = viewModel.isAnswerVisible ? 104 : 72
        let minCenter = badgeBottom + cardTopGap + cardHeight / 2
        let maxCenter = max(minCenter, availableHeight - bottomGap - cardHeight / 2)
        let desiredCenter = availableHeight / 2

        return min(max(desiredCenter, minCenter), maxCenter)
    }

    private func cardWidth(for card: ReviewCard, availableWidth: CGFloat) -> CGFloat {
        let longest = max(card.prompt.count, card.answer.count, card.word.comment.count)
        let estimatedTextWidth = CGFloat(longest) * 13 + 220
        let availableWidth = max(360, availableWidth - 120)
        return min(560, max(500, min(availableWidth * 0.62, estimatedTextWidth)))
    }

    private func cardHeight(for card: ReviewCard, width: CGFloat) -> CGFloat {
        if viewModel.isAnswerVisible {
            let commentExtra: CGFloat = card.word.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 28
            return min(260, max(220, width * 0.34 + commentExtra))
        }

        return 180
    }

    private func reviewCard(_ card: ReviewCard, width: CGFloat, height: CGFloat) -> some View {
        Button {
            viewModel.revealAnswer()
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Lexa.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Lexa.cardBorder)
                    }
                    .shadow(color: .black.opacity(viewModel.isAnswerVisible ? 0.05 : 0.03), radius: viewModel.isAnswerVisible ? 24 : 4, y: viewModel.isAnswerVisible ? 8 : 1)

                Text(card.directionLabel)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Lexa.tertiaryText)
                    .padding(.top, 14)
                    .padding(.leading, 18)

                if viewModel.isAnswerVisible {
                    revealedCard(card)
                } else {
                    hiddenCard(card)
                }
            }
            .frame(width: width)
            .frame(height: height)
            .animation(.easeInOut(duration: 0.20), value: viewModel.isAnswerVisible)
        }
        .buttonStyle(LexaHoverStyle(shape: .rounded(14)))
        .keyboardShortcut(.space, modifiers: [])
    }

    private func hiddenCard(_ card: ReviewCard) -> some View {
        ZStack {
            Text(card.prompt)
                .font(card.isEnglishPrompt ? .lexaSerif(size: 46, weight: .medium) : .system(size: 34, weight: .medium))
                .foregroundStyle(Lexa.text)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 34)

            if card.isEnglishPrompt {
                speakerButton(size: 34) {
                    viewModel.speakCurrentEnglish()
                }
                .offset(y: 62)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var spaceRevealHint: some View {
        HStack(spacing: 6) {
            Text("Space")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Lexa.tertiaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Lexa.hover, in: RoundedRectangle(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Lexa.separator)
                }

            Text("to reveal")
                .font(.system(size: 12))
                .foregroundStyle(Lexa.tertiaryText)
        }
    }

    private func revealedCard(_ card: ReviewCard) -> some View {
        VStack(spacing: 0) {
            LexaSectionLabel(text: card.direction == .enToRu ? "English" : "Russian")
                .padding(.bottom, 8)

            HStack(spacing: 12) {
                Text(card.prompt)
                    .font(card.isEnglishPrompt ? .lexaSerif(size: 34, weight: .medium) : .system(size: 28, weight: .medium))
                    .foregroundStyle(Lexa.text)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)

                if card.isEnglishPrompt {
                    speakerButton(size: 30) {
                        viewModel.speakCurrentEnglish()
                    }
                }
            }

            Rectangle()
                .fill(Lexa.separator)
                .frame(width: 32, height: 1)
                .padding(.vertical, 16)

            LexaSectionLabel(text: card.direction == .enToRu ? "Russian" : "English")
                .padding(.bottom, 8)

            HStack(spacing: 12) {
                Text(card.answer)
                    .font(card.isEnglishPrompt ? .system(size: 24, weight: .medium) : .lexaSerif(size: 34, weight: .medium))
                    .foregroundStyle(Lexa.text)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)

                if !card.isEnglishPrompt {
                    speakerButton(size: 28) {
                        viewModel.speakCurrentEnglish()
                    }
                }
            }

            if !card.word.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("“\(card.word.comment)”")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundStyle(Lexa.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 18)
                    .padding(.horizontal, 34)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 36)
        .padding(.vertical, 28)
    }

    private func speakerButton(size: CGFloat = 36, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2")
                .font(.system(size: size == 36 ? 16 : 14, weight: .regular))
                .foregroundStyle(Lexa.secondaryText)
                .frame(width: size, height: size)
                .background(Color.clear, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Lexa.separator)
                }
                .contentShape(Circle())
        }
        .buttonStyle(LexaHoverStyle(shape: .circle))
    }

    private func judgmentButton(
        title: String,
        systemImage: String,
        color: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 18, height: 18)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 26)
            .frame(minWidth: 120)
            .frame(height: 42)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(LexaHoverStyle(shape: .rounded(8)))
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "rectangle.stack")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Lexa.tertiaryText)
                .frame(width: 60, height: 60)
                .background(Lexa.hover, in: RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 18)

            Text("No words yet")
                .font(.lexaSerif(size: 26, weight: .medium))
                .foregroundStyle(Lexa.text)
                .padding(.bottom, 8)

            Text("Add your first word to start learning. New words begin at level 0 and appear in your next session.")
                .font(.system(size: 14))
                .foregroundStyle(Lexa.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 360)

            Spacer()
        }
    }
}
