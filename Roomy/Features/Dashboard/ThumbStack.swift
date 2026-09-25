// Why: a few of the actual items say more than a number — people recognise their own photos. Each kind keeps
// its own shape (screenshots tall, videos wide with a play mark, contacts as initials) inside the tile's
// tinted well. With nothing to show, one glyph says why; while scanning, placeholders hold the space, and the
// items fade in over them when they arrive.
import SwiftUI

struct ThumbStack: View {
    let preview: CategoryTile.Preview
    /// The category's colour, for initials and the "all clear" check.
    let tint: Color

    var body: some View {
        Group {
            switch preview {
            case .loading:
                HStack(spacing: Space.s8) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous)
                            .fill(RoomyColor.ringUsed.opacity(0.35))
                            .frame(width: Layout.tilePhoto, height: Layout.tilePhoto)
                    }
                }
            case .photos(let ids): photos(ids)
            case .screenshots(let ids): screenshots(ids)
            case .videos(let ids): videos(ids)
            case .initials(let letters): initials(letters)
            case .status(let status): glyph(status)
            }
        }
        .transition(.opacity)
        .animation(Motion.quick, value: preview)
        // The well has a fixed height, so its glyphs stay at a size that fits it; the tile's words carry the meaning.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityHidden(true)
    }

    private func photos(_ ids: [String]) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous)
        return HStack(spacing: -Layout.tilePhotoOverlap) {
            ForEach(ids.prefix(3), id: \.self) { id in
                thumbnail(id, size: CGSize(width: Layout.tilePhoto, height: Layout.tilePhoto))
                    .clipShape(shape)
                    .overlay(shape.strokeBorder(RoomyColor.card, lineWidth: 2))
            }
        }
    }

    private func screenshots(_ ids: [String]) -> some View {
        HStack(spacing: Space.s8) {
            ForEach(ids.prefix(4), id: \.self) { id in
                thumbnail(id, size: Layout.tileScreenshot)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
            }
        }
    }

    private func videos(_ ids: [String]) -> some View {
        HStack(spacing: Space.s8) {
            ForEach(ids.prefix(2), id: \.self) { id in
                thumbnail(id, size: Layout.tileVideo)
                    .overlay { playMark }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.grid, style: .continuous))
            }
        }
    }

    private func initials(_ letters: [String]) -> some View {
        HStack(spacing: -Layout.tileAvatarOverlap) {
            ForEach(Array(letters.prefix(3).enumerated()), id: \.offset) { _, letter in
                Text(letter)
                    .font(RoomyFont.subheadlineSemibold)
                    .foregroundStyle(tint)
                    .frame(width: Layout.tileAvatar, height: Layout.tileAvatar)
                    .background(tint.opacity(0.18), in: Circle())
                    .background(RoomyColor.card, in: Circle())
                    .overlay(Circle().strokeBorder(RoomyColor.card, lineWidth: 2))
            }
        }
    }

    private func glyph(_ status: CategoryTile.Status) -> some View {
        Image(systemName: status.symbol)
            .font(RoomyFont.footnoteSemibold)
            .foregroundStyle(status == .clear ? tint : RoomyColor.textSecondary)
            .frame(width: Layout.tileGlyph, height: Layout.tileGlyph)
            .background(RoomyColor.card, in: Circle())
    }

    private func thumbnail(_ id: String, size: CGSize) -> some View {
        AssetThumbnail(id: id, pixelSize: CGSize(width: size.width * 3, height: size.height * 3))
            .frame(width: size.width, height: size.height)
    }

    private var playMark: some View {
        Image(systemName: "play.fill")
            .font(RoomyFont.caption)
            // On a white disc in both appearances, so the glyph stays dark.
            .foregroundStyle(.black)
            .frame(width: Layout.tilePlayMark, height: Layout.tilePlayMark)
            .background(.white.opacity(0.9), in: Circle())
    }
}

extension CategoryTile.Status {
    var symbol: String {
        switch self {
        case .clear: "checkmark"
        case .locked: "lock.fill"
        case .notScanned: "magnifyingglass"
        case .paused: "pause.fill"
        case .failed: "exclamationmark"
        }
    }

    /// Nothing is waiting behind a locked, unscanned or failed tile, so its well stays neutral.
    var isNeutral: Bool { self != .clear }
}
