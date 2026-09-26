// Why: small opaque labels that sit on photos and cards. They are never glass, so they stay legible over
// busy images. A reason chip can carry the screen's category colour (Figma "ReasonChip v5", category tone),
// so the reason reads as part of that screen; without a tint it stays the neutral chip used for counts. A chip
// is one line and keeps its full width, so beside a name it is the name that wraps, never the chip (device test:
// "the pill isn't aligned"). The small size is the "from card 2" tag on a merged value's label line.
import SwiftUI

struct BestBadge: View {
    var body: some View {
        Label("Best", systemImage: "checkmark.seal.fill")
            .font(RoomyFont.footnoteSemibold)
            .foregroundStyle(RoomyColor.onAccent)
            .padding(.horizontal, Space.s8)
            .padding(.vertical, Layout.chipVerticalPadding)
            .background(RoomyColor.accent, in: Capsule())
    }
}

struct ReasonChip: View {
    enum Size {
        case regular
        /// A tag beside a small label, such as "from card 2".
        case small
    }

    let text: String
    /// The screen's soft category colour; nil keeps the neutral chip.
    var tint: Color? = nil
    var size = Size.regular

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(tint == nil ? RoomyColor.textSecondary : RoomyColor.textPrimary)
            .lineLimit(1)
            .padding(padding)
            .background(tint ?? RoomyColor.chip, in: Capsule())
            .fixedSize()
    }

    private var font: Font {
        if size == .small { return RoomyFont.caption2Semibold }
        return tint == nil ? RoomyFont.footnote : RoomyFont.footnoteSemibold
    }

    private var padding: EdgeInsets {
        switch size {
        case .regular:
            EdgeInsets(
                top: Layout.chipVerticalPadding, leading: Space.s12, bottom: Layout.chipVerticalPadding,
                trailing: Space.s12)
        case .small: Layout.sourceTagPadding
        }
    }
}

/// "2 cards → 1" on a duplicate-contacts group: the count in primary text, what it becomes in secondary.
struct CountBadge: View {
    let count: String
    let result: String

    var body: some View {
        HStack(spacing: Space.s4) {
            Text(count).foregroundStyle(RoomyColor.textPrimary)
            Text(result).foregroundStyle(RoomyColor.textSecondary)
        }
        .font(RoomyFont.footnoteSemibold)
        .lineLimit(1)
        .padding(.horizontal, Space.s12)
        .padding(.vertical, Layout.chipVerticalPadding)
        .background(RoomyColor.chip, in: Capsule())
        .fixedSize()
    }
}
