// Why: each category is a tile with a few of its actual items in a well tinted with the category's colour,
// then its name and what it holds in words, so the grid reads like content, not settings. Two tiles share a
// row; the grid drops to one column at accessibility text sizes. While numbers are coming, skeletons hold the
// place, and the real items and words fade in over them. Matches the Figma "CategoryTile v5" component.
import SwiftUI

struct CategoryCard: View {
    let tile: CategoryTile

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
                .font(RoomyFont.subheadlineSemibold)
                .foregroundStyle(RoomyColor.textPrimary)
            if let detail = tile.detail {
                Text(detail)
                    .font(RoomyFont.footnote)
                    .foregroundStyle(RoomyColor.textSecondary)
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
