import AppKit
import SwiftUI

enum Lexa {
    static let darkModeDefaultsKey = "lexa.darkMode"
    static let sidebarWidth: CGFloat = 184
    static let toolbarHeight: CGFloat = 44
    static let detailToolbarHeight: CGFloat = 40

    static var accent: Color {
        Color(nsColor(light: "#0a84ff", dark: "#0a84ff"))
    }

    static var green: Color {
        Color(nsColor(light: "#1f9d3c", dark: "#30d158"))
    }

    static var red: Color {
        Color(nsColor(light: "#d93025", dark: "#ff453a"))
    }

    static var windowBackground: Color {
        Color(nsColor(light: "#fdfcf9", dark: "#1e1e1e"))
    }

    static var sidebarBackground: Color {
        Color(nsColor(light: "#efeeeb", dark: "#2a2a2a"))
    }

    static var toolbarBackground: Color {
        Color(nsColor(light: "#f8f7f4", dark: "#282828")).opacity(0.92)
    }

    static var cardBackground: Color {
        Color(nsColor(light: "#fffefa", dark: "#262626"))
    }

    static var inputBackground: Color {
        Color(nsColor(light: "#fffefa", dark: "#2a2a2a"))
    }

    static var text: Color {
        Color(nsColor(light: "#000000", dark: "#ffffff", lightAlpha: 0.88, darkAlpha: 0.92))
    }

    static var secondaryText: Color {
        Color(nsColor(light: "#000000", dark: "#ffffff", lightAlpha: 0.55, darkAlpha: 0.60))
    }

    static var tertiaryText: Color {
        Color(nsColor(light: "#000000", dark: "#ffffff", lightAlpha: 0.35, darkAlpha: 0.38))
    }

    static var separator: Color {
        Color(nsColor(light: "#3a3329", dark: "#ffffff", lightAlpha: 0.09, darkAlpha: 0.08))
    }

    static var hover: Color {
        Color(nsColor(light: "#3a3329", dark: "#ffffff", lightAlpha: 0.045, darkAlpha: 0.06))
    }

    static var selection: Color {
        Color(nsColor(light: "#3a3329", dark: "#ffffff", lightAlpha: 0.07, darkAlpha: 0.10))
    }

    static var badgeBackground: Color {
        Color(nsColor(light: "#3a3329", dark: "#ffffff", lightAlpha: 0.075, darkAlpha: 0.10))
    }

    static var cardBorder: Color {
        Color(nsColor(light: "#3a3329", dark: "#ffffff", lightAlpha: 0.09, darkAlpha: 0.07))
    }

    static var inputBorder: Color {
        Color(nsColor(light: "#3a3329", dark: "#ffffff", lightAlpha: 0.15, darkAlpha: 0.10))
    }

    static var greenBackground: Color {
        Color(nsColor(light: "#1f9d3c", dark: "#30d158", lightAlpha: 0.10, darkAlpha: 0.16))
    }

    static var redBackground: Color {
        Color(nsColor(light: "#d93025", dark: "#ff453a", lightAlpha: 0.08, darkAlpha: 0.16))
    }

    @MainActor
    static func applyAppearance(isDarkMode: Bool) {
        NSApp.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
    }

    private static func nsColor(
        light: String,
        dark: String,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> NSColor {
        NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua
                ? NSColor(hex: dark, alpha: darkAlpha)
                : NSColor(hex: light, alpha: lightAlpha)
        }
    }
}

extension Font {
    static func lexaSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

private extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: value)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = CGFloat((rgb >> 16) & 0xff) / 255
        let green = CGFloat((rgb >> 8) & 0xff) / 255
        let blue = CGFloat(rgb & 0xff) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

struct LexaToolbar: View {
    var title: String
    var left: AnyView = AnyView(EmptyView())
    var right: AnyView = AnyView(EmptyView())

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Lexa.text)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                left

                Spacer()

                right
            }
        }
        .padding(.horizontal, 14)
        .frame(height: Lexa.toolbarHeight)
        .background(Lexa.toolbarBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Lexa.separator)
                .frame(height: 0.5)
        }
    }
}

struct LexaHoverStyle: ButtonStyle {
    enum Shape: Equatable {
        case rounded(CGFloat)
        case circle
    }

    var shape: Shape = .rounded(6)

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, shape: shape)
    }

    private struct StyleBody: View {
        let configuration: Configuration
        let shape: Shape

        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .overlay {
                    if isEnabled, isHovering || configuration.isPressed {
                        anyShape
                            .fill(configuration.isPressed ? Lexa.selection : Lexa.hover)
                            .allowsHitTesting(false)
                    }
                }
                .onHover { isHovering = $0 }
                .animation(.easeInOut(duration: 0.12), value: isHovering)
                .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
        }

        private var anyShape: AnyShape {
            switch shape {
            case .rounded(let radius):
                AnyShape(RoundedRectangle(cornerRadius: radius))
            case .circle:
                AnyShape(Circle())
            }
        }
    }
}

struct LexaIconButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Lexa.secondaryText)
                .frame(width: 26, height: 26)
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(LexaHoverStyle())
        .help(title)
    }
}

struct LexaToolbarButton: View {
    var title: String
    var systemImage: String?
    var isPrimary = false
    var isDisabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .medium))
                }

                Text(title)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isPrimary ? Color.white : isDisabled ? Lexa.tertiaryText : Lexa.text)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(isPrimary ? Lexa.accent : Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(LexaHoverStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

struct LexaSectionLabel: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Lexa.tertiaryText)
    }
}

struct LexaFieldLabel: View {
    var title: String
    var optional = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Lexa.secondaryText)

            if optional {
                Text("optional")
                    .font(.system(size: 10))
                    .foregroundStyle(Lexa.tertiaryText)
            }
        }
    }
}

struct LexaPrimaryButton: View {
    var title: String
    var isDisabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background(Lexa.accent, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(LexaHoverStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
    }
}

struct LexaSecondaryButton: View {
    var title: String
    var isDisabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isDisabled ? Lexa.tertiaryText : Lexa.text)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(Lexa.hover, in: RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Lexa.separator)
                }
        }
        .buttonStyle(LexaHoverStyle())
        .disabled(isDisabled)
    }
}

struct LexaToast: View {
    var word: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Lexa.green)
                .frame(width: 22, height: 22)
                .background(Lexa.greenBackground, in: Circle())

            HStack(spacing: 0) {
                Text("Added ")
                    .font(.system(size: 13))

                Text(word)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Lexa.text)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Lexa.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .contentShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(LexaHoverStyle(shape: .rounded(4)))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Lexa.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Lexa.cardBorder)
        }
        .shadow(color: .black.opacity(0.12), radius: 20, y: 6)
    }
}
