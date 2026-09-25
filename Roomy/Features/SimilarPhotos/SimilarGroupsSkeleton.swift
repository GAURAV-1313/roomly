// Why: comparing photos takes minutes, so Similar Photos shows the real progress — Roomy thinking, the counts and
// a bar — above skeleton groups in the shape the results will take (Figma "Similar Photos — comparing"). The
// counts are the only numbers on screen, and they are real.
import SwiftUI

struct SimilarGroupsSkeleton: View {
    let copy: ScanProgressCopy

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s16) {
                ScanProgressCard(copy: copy, route: .similarPhotos)
                SkeletonShape.line(width: Layout.skeletonMonthWidth, height: Layout.skeletonTitleHeight)
                    .padding(.top, Space.s8)
                    .padding(.horizontal, Space.s4)
                ForEach(0..<Layout.skeletonGroupCount, id: \.self) { _ in group }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Space.margin)
            .padding(.bottom, Layout.bottomBarClearance)
        }
        .background(RoomyColor.bg)
    }

    private var group: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            SkeletonShape.line(width: Layout.skeletonGroupHeaderWidth, height: Layout.skeletonLineHeight)
            HStack(spacing: Space.s8) {
                ForEach(0..<Layout.skeletonGroupTiles, id: \.self) { _ in
                    SkeletonShape(width: Layout.photoTileSize, height: Layout.photoTileSize, cornerRadius: Radius.row)
                }
            }
            SkeletonShape.line(width: Layout.skeletonGroupFooterWidth)
        }
        .padding(Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }
}
