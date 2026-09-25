// Why: every button is an iOS 26 capsule. Prominent buttons get Liquid Glass on iOS 26 and a solid fill
// below it, from one style, so no screen hand-rolls a button. The one destructive button is red glass: a
// lighter tint lets the glass show, while the solid fallback keeps full red. `.controlSize(.small)` gives
// the compact capsule used inside cards (Figma "QuietCapsule v5").
import SwiftUI

enum RoomyButtonKind {
    case primary
    case secondary
    case destructive
    case text

    var height: CGFloat {
        switch self {
        case .primary, .destructive: 56
        case .secondary: 48
        case .text: Layout.tapTarget
        }
    }

    var foreground: Color {
        switch self {
        case .primary, .destructive: RoomyColor.onAccent
        case .secondary, .text: RoomyColor.accent
        }
    }

    var fill: Color? {
        switch self {
        case .primary: RoomyColor.accent
        case .destructive: RoomyColor.destructive
        case .secondary: RoomyColor.accentTint
        case .text: nil
        }
    }

    var isProminent: Bool { self == .primary || self == .destructive }
}

struct RoomyButtonStyle: ButtonStyle {
    let kind: RoomyButtonKind

    @Environment(\.controlSize) private var controlSize

    private var isSmall: Bool { controlSize == .small || controlSize == .mini }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isSmall ? RoomyFont.subheadlineSemibold : RoomyFont.headline)
            .foregroundStyle(kind.foreground)
            .padding(.horizontal, isSmall ? Space.s16 : 0)
            .frame(maxWidth: isSmall ? nil : .infinity)
            .frame(minHeight: isSmall ? Layout.smallButtonHeight : kind.height)
            .modifier(ButtonSurface(kind: kind))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Prominent buttons are tinted glass (solid below iOS 26); secondary ones a soft fill; text buttons nothing.
private struct ButtonSurface: ViewModifier {
    /// How strongly the red tints the glass: enough to read as the delete button, light enough to be glass.
    static let redGlassTint = 0.8

    let kind: RoomyButtonKind

    @ViewBuilder
    func body(content: Content) -> some View {
        if kind == .destructive {
            content.roomyGlass(in: Capsule(), style: .prominent(RoomyColor.destructive, glassTint: Self.redGlassTint))
        } else if let fill = kind.fill, kind.isProminent {
            content.roomyGlass(in: Capsule(), style: .prominent(fill))
        } else if let fill = kind.fill {
            content.background(fill, in: Capsule())
        } else {
            content
        }
    }
}

extension ButtonStyle where Self == RoomyButtonStyle {
    static var roomyPrimary: RoomyButtonStyle { RoomyButtonStyle(kind: .primary) }
    static var roomySecondary: RoomyButtonStyle { RoomyButtonStyle(kind: .secondary) }
    static var roomyDestructive: RoomyButtonStyle { RoomyButtonStyle(kind: .destructive) }
    static var roomyText: RoomyButtonStyle { RoomyButtonStyle(kind: .text) }
}
