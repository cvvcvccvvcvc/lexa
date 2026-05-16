import SwiftUI

struct LexaSidebar: View {
    @Binding var selection: SidebarSection
    var dueCount: Int
    var wordsCount: Int

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: Lexa.toolbarHeight)

            VStack(spacing: 1) {
                sidebarButton(
                    section: .learn,
                    icon: "rectangle.stack",
                    count: dueCount > 0 ? dueCount : nil
                )
                sidebarButton(section: .addWord, icon: "plus", count: nil)
                sidebarButton(section: .words, icon: "list.bullet", count: wordsCount)
            }
            .padding(.top, 14)

            Spacer()
        }
        .frame(width: Lexa.sidebarWidth)
        .background(Lexa.sidebarBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Lexa.separator)
                .frame(width: 0.5)
        }
    }

    private func sidebarButton(
        section: SidebarSection,
        icon: String,
        count: Int?
    ) -> some View {
        Button {
            selection = section
        } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 15)
                    .foregroundStyle(selection == section ? .white : Lexa.secondaryText)

                Text(section.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(selection == section ? .white : Lexa.text)

                Spacer()

                if let count {
                    Text("\(count)")
                        .font(.system(size: 11))
                        .foregroundStyle(selection == section ? .white.opacity(0.85) : Lexa.secondaryText)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 25)
            .background(
                selection == section ? Lexa.accent : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}
