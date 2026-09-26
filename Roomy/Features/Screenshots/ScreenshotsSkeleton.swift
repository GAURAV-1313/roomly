// Why: indexing screenshots usually takes under a second, and when it takes longer the screen should already
// look like itself: the line under the title, then the grid with the same columns and 9:16 tiles the real
// screenshots will fill (Figma "Screenshots — indexing"). No counts are shown, because none are known yet.
import SwiftUI

struct ScreenshotsSkeleton: View {
    let columns: [GridItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s12) {
                CategorySubtitleSkeleton()
                LazyVGrid(columns: columns, spacing: Layout.screenshotGutter) {
                    ForEach(0..<columns.count * Layout.skeletonScreenshotRows, id: \.self) { _ in
                        SkeletonShape(cornerRadius: Radius.grid)
                            .aspectRatio(9 / 16, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal, Space.margin)
        }
        .scrollDisabled(true)
        .background(RoomyColor.bg)
        .loadingScreen("Scanning your photos")
    }
}
