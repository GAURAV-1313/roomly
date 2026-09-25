// Why: every piece of Liquid Glass goes through this one modifier, so there is exactly one iOS 17/18
// fallback to get right. Glass belongs to the navigation layer only; content stays opaque. Over photos the
// clear variant keeps the image's colours; prominent actions are tinted glass, never a fill under glass.
import SwiftUI

enum GlassStyle {
    /// Toolbars and bars over app content.
    case regular
    /// Controls over full-bleed photos or video.
    case clear
    /// The one primary action on a surface, tinted with its colour. `glassTint` below 1 lets more glass show
    /// through the tint on iOS 26; the solid fallback always uses the full colour.
    case prominent(Color, glassTint: Double = 1)
}

struct RoomyGlass<GlassShape: InsettableShape>: ViewModifier {
    let shape: GlassShape
    let style: GlassStyle

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else {
            switch style {
            case .prominent(let color, _):
                content.background(color, in: shape)
            case .regular, .clear:
                content
                    .background(.ultraThinMaterial, in: shape)
                    .overlay(shape.strokeBorder(RoomyColor.glassStroke, lineWidth: 0.5))
            }
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        switch style {
        case .regular: .regular.interactive()
        case .clear: .clear.interactive()
        case .prominent(let color, let glassTint): .regular.tint(color.opacity(glassTint)).interactive()
        }
    }
}

extension View {
    /// Liquid Glass on iOS 26, a material (or, for prominent actions, a solid) shape below.
    func roomyGlass<GlassShape: InsettableShape>(in shape: GlassShape = Capsule(), style: GlassStyle = .regular)
        -> some View
    {
        modifier(RoomyGlass(shape: shape, style: style))
    }
}
