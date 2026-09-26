// Why: each category is a tile with a few of its actual items in a well tinted with the category's colour,
// then its name and what it holds in one short line, so the grid reads like content, not settings. Two tiles share
// a row, so the line never wraps there; at accessibility text sizes the grid drops to one column and the line may
// wrap rather than cut off. VoiceOver reads the tile's full sentence instead of the short line. While numbers are
// coming, skeletons hold the place, and the real items and words fade in over them. Matches the Figma
// "CategoryTile v5" component (board "Fix 2 — Dashboard tiles & storage card text").
import SwiftUI

struct CategoryCard: View {
    let tile: CategoryTile

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s8) {
            ThumbStack(preview: tile.preview, tint: tile.route.categoryTint)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.tileWellHeight)
                .background(wellFill, in: RoundedRectangle(cornerRadius: Radius.well, style: .continuous))
            text
                .padding(.horizontal, Space.s4)
        }
        .padding([.top, .horizontal], Layout.tileInset)
        .padding(.bottom, Layout.tileBottomInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .dashboardCard()
        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var wellFill: Color {
        switch tile.preview {
        case .loading: RoomyColor.ringTrack
        case .status(let status) where status.isNeutral: RoomyColor.chip
        default: tile.route.categoryTintSoft
        }
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(tile.name)
                .font(RoomyFont.footnoteSemibold)
                .foregroundStyle(RoomyColor.textPrimary)
            if let detail = tile.detail {
                Text(detail)
                    .font(RoomyFont.caption)
                    .foregroundStyle(RoomyColor.textSecondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .accessibilityLabel(tile.accessibilityDetail ?? detail)
                    .transition(.opacity)
            } else {
                // Not a SkeletonShape: this one carries the tile's "Loading" label for VoiceOver.
                Capsule()
                    .fill(RoomyColor.ringTrack)
                    .frame(width: Layout.skeletonLineWidth, height: Layout.skeletonLineHeight)
                    .padding(.top, Space.s4)
                    .accessibilityLabel("Loading")
                    .transition(.opacity)
            }
        }
        .animation(Motion.quick, value: tile.detail)
        .fixedSize(horizontal: false, vertical: true)
    }
}
