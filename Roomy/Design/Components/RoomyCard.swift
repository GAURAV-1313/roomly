// Why: cards are content, not chrome: opaque white, 24-point continuous corners, a hairline border and no
// shadow. One modifier draws that background so every card in the app matches. The dashboard's cards float
// on the parchment with a soft shadow instead of a hairline (Figma v5), from their own modifier.
import SwiftUI

struct CardBackground: ViewModifier {
    var isHighlighted = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        content
            .background(RoomyColor.card, in: shape)
            .overlay(
                shape.strokeBorder(
                    isHighlighted ? RoomyColor.accent : RoomyColor.separator,
                    lineWidth: isHighlighted ? 1.5 : 1))
    }
}

extension View {
    func cardBackground(isHighlighted: Bool = false) -> some View {
        modifier(CardBackground(isHighlighted: isHighlighted))
    }

    /// The accent outline a selected card wears (a video row, a contact group).
    func selectedRing(_ isSelected: Bool) -> some View {
        overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(RoomyColor.accent, lineWidth: Layout.selectedRingWidth)
            }
        }
    }

    /// White card with a soft shadow, for the dashboard's tiles and notices. The shadow belongs to the card's
    /// shape only; on the whole view it would fall behind every line of text too.
    func dashboardCard() -> some View {
        background {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(RoomyColor.card)
                .shadow(color: RoomyColor.cardShadow, radius: Layout.cardShadowRadius, y: Layout.cardShadowY)
        }
    }
}

struct RoomyCard<Content: View>: View {
    var padding: CGFloat = Space.s16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBackground()
    }
}
