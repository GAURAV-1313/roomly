// Why: Review's total, the cleanup's steps and the result all open with the dashboard's hero card — the navy to
// parchment wash with Roomy perched on a white card — so the sheet reads as the same family as the screen
// behind it. One modifier draws the wash, and one the white card inside it, so the three never drift apart.
import SwiftUI

extension View {
    /// The hero wash behind content, with the soft card shadow on the shape only, never behind the text.
    func heroShell(cornerRadius: CGFloat = Radius.heroCard) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [RoomyColor.heroTintTop, RoomyColor.heroTintBottom], startPoint: .top,
                        endPoint: .bottom)
                )
                .shadow(color: RoomyColor.cardShadow, radius: Layout.cardShadowRadius, y: Layout.cardShadowY)
        }
    }

    /// The white card nested in a hero shell, 24-point corners inside the shell's 32.
    func heroInnerCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background(RoomyColor.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}
