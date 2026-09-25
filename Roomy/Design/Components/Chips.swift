// Why: small opaque labels that sit on photos and cards. They are never glass, so they stay legible over
// busy images. A reason chip can carry the screen's category colour (Figma "ReasonChip v5", category tone),
// so the reason reads as part of that screen; without a tint it stays the neutral chip used for counts.
import SwiftUI

struct BestBadge: View {
    var body: some View {
        Label("Best", systemImage: "checkmark.seal.fill")
            .font(RoomyFont.footnoteSemibold)
            .foregroundStyle(RoomyColor.onAccent)
            .padding(.horizontal, Space.s8)
            .padding(.vertical, 3)
            .background(RoomyColor.accent, in: Capsule())
    }
}

struct ReasonChip: View {
    let text: String
    /// The screen's soft category colour; nil keeps the neutral chip.
    var tint: Color? = nil

    var body: some View {
        Text(text)
            .font(tint == nil ? RoomyFont.footnote : RoomyFont.footnoteSemibold)
            .foregroundStyle(tint == nil ? RoomyColor.textSecondary : RoomyColor.textPrimary)
            .padding(.horizontal, Space.s12)
            .padding(.vertical, 3)
            .background(tint ?? RoomyColor.chip, in: Capsule())
    }
}
