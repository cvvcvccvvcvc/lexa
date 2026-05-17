import SwiftUI

struct LexaSidebar: View {
    @Binding var selection: SidebarSection

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: Lexa.toolbarHeight)

            VStack(spacing: 1) {
                sidebarButton(section: .learn, icon: "rectangle.stack")
                sidebarButton(section: .addWord, icon: "plus")
                sidebarButton(section: .words, icon: "list.bullet")
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

    private func sidebarButton(section: SidebarSection, icon: String) -> some View {
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
        .buttonStyle(LexaHoverStyle())
        .padding(.horizontal, 8)
    }
}
