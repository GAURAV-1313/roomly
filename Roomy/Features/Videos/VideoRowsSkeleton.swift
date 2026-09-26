// Why: while videos are indexed the screen keeps its final shape: the line under the title, then rows with a
// poster, two lines of words and the check where the size column will be (Figma "Large Videos — indexing"). The
// skeletons hold the space; no size or count is shown until it is real.
import SwiftUI

struct VideoRowsSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Space.s12) {
                CategorySubtitleSkeleton()
                ForEach(0..<Layout.skeletonVideoRows, id: \.self) { _ in row }
            }
            .padding(.horizontal, Space.margin)
        }
        .scrollDisabled(true)
        .background(RoomyColor.bg)
        .loadingScreen("Scanning your videos")
    }

    private var row: some View {
        HStack(spacing: Space.s12) {
            SkeletonShape(
                width: Layout.videoPoster.width, height: Layout.videoPoster.height, cornerRadius: Radius.control)
            VStack(alignment: .leading, spacing: Space.s8) {
                SkeletonShape.line(width: Layout.skeletonFilenameWidth, height: Layout.skeletonLineHeight)
                SkeletonShape.line(width: Layout.skeletonDetailWidth)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            SkeletonShape(
                width: Layout.selectionCheck, height: Layout.selectionCheck, cornerRadius: Layout.selectionCheck / 2)
        }
        .padding([.leading, .vertical], Space.s8)
        .padding(.trailing, Layout.videoRowTrailingInset)
        .dashboardCard()
    }
}
