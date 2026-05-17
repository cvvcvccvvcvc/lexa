import SwiftUI
import VocabularyCore
import VocabularyInfrastructure

enum WordsSort: String, CaseIterable, Identifiable {
    case recent
    case english
    case level

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent:
            "Recent"
        case .english:
            "A -> Z"
        case .level:
            "Level"
        }
    }
}

struct WordsView: View {
    let repository: WordRepository
    var onWordsChanged: () -> Void = {}

    @StateObject private var viewModel = WordsViewModel()
    @FocusState private var focusedField: Field?
    @State private var search = ""
    @State private var sortBy: WordsSort = .recent
    @State private var isEditing = false

    private enum Field {
        case english
        case russian
        case comment
        case search
    }

    private var filteredWords: [VocabularyWord] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var result = viewModel.words

        if !query.isEmpty {
            result = result.filter {
                $0.englishText.lowercased().contains(query) ||
                    $0.russianTranslation.lowercased().contains(query) ||
                    $0.comment.lowercased().contains(query)
            }
        }

        switch sortBy {
        case .recent:
            return result
        case .english:
            return result.sorted {
                $0.englishText.localizedCaseInsensitiveCompare($1.englishText) == .orderedAscending
            }
        case .level:
            return result.sorted { $0.level > $1.level }
        }
    }

    private var listWidth: CGFloat? {
        viewModel.selectedWord == nil ? nil : 360
    }

    var body: some View {
        ZStack {
            if viewModel.words.isEmpty {
                emptyState
            } else {
                HStack(spacing: 0) {
                    listPane

                    if viewModel.selectedWord != nil {
                        detailPane
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .background(Lexa.windowBackground)
        .task {
            viewModel.load(repository: repository)
        }
        .onChange(of: viewModel.selectedID) { _, _ in
            isEditing = false
            focusedField = nil
        }
        .alert("Delete this word?", isPresented: $viewModel.isDeleteConfirmationPresented) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSelected(repository: repository)
                onWordsChanged()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            if let selectedWord = viewModel.selectedWord {
                Text("This will remove “\(selectedWord.englishText)” and its learning progress. This action cannot be undone.")
            } else {
                Text("This cannot be undone.")
            }
        }
    }

    private var listPane: some View {
        VStack(spacing: 0) {
            searchAndSort

            headerRow

            if filteredWords.isEmpty {
                VStack(spacing: 0) {
                    Spacer()
                    Text("No words match “\(search)”.")
                        .font(.system(size: 13))
                        .foregroundStyle(Lexa.secondaryText)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredWords) { word in
                            wordRow(word)
                        }
                    }
                }
            }

            footer
        }
        .frame(width: listWidth)
        .frame(maxWidth: viewModel.selectedWord == nil ? .infinity : 360)
        .overlay(alignment: .trailing) {
            if viewModel.selectedWord != nil {
                Rectangle()
                    .fill(Lexa.separator)
                    .frame(width: 0.5)
            }
        }
    }

    private var searchAndSort: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(Lexa.secondaryText)

                TextField("Search words", text: $search)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Lexa.text)
                    .focused($focusedField, equals: .search)

                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Lexa.tertiaryText)
                            .frame(width: 18, height: 18)
                            .contentShape(Circle())
                    }
                    .buttonStyle(LexaHoverStyle(shape: .circle))
                }
            }
            .padding(.horizontal, 9)
            .frame(height: 28)
            .background(Lexa.hover, in: RoundedRectangle(cornerRadius: 6))

            Picker("Sort", selection: $sortBy) {
                ForEach(WordsSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 92)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Lexa.separator)
                .frame(height: 0.5)
        }
    }

    private var headerRow: some View {
        HStack(spacing: 20) {
            headerCell("English")

            if viewModel.selectedWord == nil {
                headerCell("Russian")
            }

            headerCell("Level", alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .frame(height: 32)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Lexa.separator)
                .frame(height: 0.5)
        }
    }

    private func headerCell(_ text: String, alignment: Alignment = .leading) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Lexa.tertiaryText)
            .frame(maxWidth: text == "Level" ? 60 : .infinity, alignment: alignment)
    }

    private func wordRow(_ word: VocabularyWord) -> some View {
        Button {
            viewModel.select(id: word.id)
        } label: {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(word.englishText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Lexa.text)
                        .lineLimit(1)

                    if viewModel.selectedWord != nil {
                        Text(word.russianTranslation)
                            .font(.system(size: 12))
                            .foregroundStyle(Lexa.secondaryText)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.selectedWord == nil {
                    Text(word.russianTranslation)
                        .font(.system(size: 14))
                        .foregroundStyle(Lexa.secondaryText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("\(word.level)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Lexa.secondaryText)
                    .monospacedDigit()
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .frame(height: viewModel.selectedWord == nil ? 42 : 52)
            .background(viewModel.selectedID == word.id ? Lexa.selection : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(LexaHoverStyle(shape: .rounded(0)))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Lexa.separator)
                .frame(height: 0.5)
        }
    }

    private var footer: some View {
        HStack {
            Text("\(filteredWords.count) of \(viewModel.words.count)")

            let due = ScheduledReviewScheduler.eligibleWords(from: viewModel.words, now: Date()).count
            if due > 0 {
                Text("· \(due) due")
            }

            Spacer()
        }
        .font(.system(size: 11))
        .foregroundStyle(Lexa.tertiaryText)
        .padding(.horizontal, 16)
        .frame(height: 30)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Lexa.separator)
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selectedWord = viewModel.selectedWord {
            VStack(spacing: 0) {
                detailToolbar

                ScrollView {
                    detailContent(selectedWord)
                    .frame(maxWidth: 540, alignment: .leading)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var detailToolbar: some View {
        HStack(spacing: 8) {
            LexaToolbarButton(title: "Back", systemImage: "chevron.left") {
                viewModel.select(id: nil)
            }

            Spacer()

            if isEditing {
                LexaToolbarButton(title: "Cancel", systemImage: "xmark") {
                    cancelEditing()
                }

                LexaToolbarButton(title: "Save", systemImage: "checkmark", isPrimary: true, isDisabled: !viewModel.canSave) {
                    viewModel.save(repository: repository)
                    isEditing = false
                    focusedField = nil
                    onWordsChanged()
                }
            } else {
                LexaToolbarButton(title: "Edit", systemImage: "pencil", isPrimary: true) {
                    isEditing = true
                    focusedField = .english
                }
            }

            LexaToolbarButton(title: "Delete", systemImage: "trash") {
                viewModel.isDeleteConfirmationPresented = true
            }
        }
        .padding(.horizontal, 14)
        .frame(height: Lexa.detailToolbarHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Lexa.separator)
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private func detailContent(_ selectedWord: VocabularyWord) -> some View {
        if isEditing {
            editContent(selectedWord)
        } else {
            readContent(selectedWord)
        }
    }

    private func readContent(_ selectedWord: VocabularyWord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LexaSectionLabel(text: "English")
                .padding(.bottom, 6)

            HStack(spacing: 14) {
                Text(selectedWord.englishText)
                    .font(.lexaSerif(size: 34, weight: .medium))
                    .foregroundStyle(Lexa.text)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                Button {
                    viewModel.speakSelectedEnglish()
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 14))
                        .foregroundStyle(Lexa.secondaryText)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Circle()
                                .stroke(Lexa.separator)
                        }
                }
                .buttonStyle(LexaHoverStyle(shape: .circle))
            }
            .padding(.bottom, 24)

            LexaSectionLabel(text: "Russian")
                .padding(.bottom, 6)

            Text(selectedWord.russianTranslation)
                .font(.system(size: 20))
                .foregroundStyle(Lexa.text)
                .padding(.bottom, 24)

            if !selectedWord.comment.isEmpty {
                LexaSectionLabel(text: "Comment")
                    .padding(.bottom, 6)

                Text("“\(selectedWord.comment)”")
                    .font(.system(size: 14))
                    .italic()
                    .foregroundStyle(Lexa.text)
                    .lineSpacing(4)
                    .padding(.bottom, 26)
            }

            levelCard(selectedWord)
        }
    }

    private func editContent(_ selectedWord: VocabularyWord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LexaSectionLabel(text: "English")
                .padding(.bottom, 6)

            HStack(spacing: 14) {
                TextField("English", text: $viewModel.englishText)
                    .textFieldStyle(.plain)
                    .font(.lexaSerif(size: 34, weight: .medium))
                    .foregroundStyle(Lexa.text)
                    .focused($focusedField, equals: .english)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 42)
                    .background(Lexa.inputBackground, in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Lexa.inputBorder)
                    }
            }
            .padding(.bottom, 24)

            LexaSectionLabel(text: "Russian")
                .padding(.bottom, 6)

            TextField("Russian", text: $viewModel.russianTranslation)
                .textFieldStyle(.plain)
                .font(.system(size: 20))
                .foregroundStyle(Lexa.text)
                .focused($focusedField, equals: .russian)
                .padding(.horizontal, 10)
                .frame(minHeight: 34)
                .background(Lexa.inputBackground, in: RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Lexa.inputBorder)
                }
                .padding(.bottom, 24)

            LexaSectionLabel(text: "Comment")
                .padding(.bottom, 6)

            ZStack(alignment: .topLeading) {
                if viewModel.comment.isEmpty {
                    Text("Memory hook, context, or usage note")
                        .font(.system(size: 13))
                        .foregroundStyle(Lexa.tertiaryText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                }

                TextEditor(text: $viewModel.comment)
                    .font(.system(size: 13))
                    .foregroundStyle(Lexa.text)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .comment)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .frame(minHeight: 54)
                    .background(Color.clear)
            }
            .background(Lexa.inputBackground, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Lexa.inputBorder)
            }
            .padding(.bottom, 26)

            levelCard(selectedWord)
        }
    }

    private func cancelEditing() {
        if let selectedID = viewModel.selectedID {
            viewModel.select(id: selectedID)
        }

        isEditing = false
        focusedField = nil
    }

    private func levelCard(_ word: VocabularyWord) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                LexaSectionLabel(text: "Level")

                HStack(spacing: 0) {
                    Text("Level \(word.level) ")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Lexa.text)

                    Text("of 9")
                        .font(.system(size: 15))
                        .foregroundStyle(Lexa.tertiaryText)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Lexa.separator)
                        .frame(height: 6)

                    Capsule()
                        .fill(word.level >= 7 ? Lexa.green : Lexa.accent)
                        .frame(width: proxy.size.width * CGFloat(word.level) / 9, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Lexa.separator)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "list.bullet")
                .font(.system(size: 28))
                .foregroundStyle(Lexa.tertiaryText)
                .frame(width: 60, height: 60)
                .background(Lexa.hover, in: RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 18)

            Text("Your library is empty")
                .font(.lexaSerif(size: 26, weight: .medium))
                .foregroundStyle(Lexa.text)
                .padding(.bottom, 8)

            Text("Words you add will appear here. You can edit, search, and review them any time.")
                .font(.system(size: 14))
                .foregroundStyle(Lexa.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 340)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Lexa.windowBackground)
    }
}
