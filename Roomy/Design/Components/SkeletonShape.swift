// Why: while numbers are still coming, a quiet shape holds the place of what will be there, so nothing jumps
// when it arrives and no made-up value is ever shown. It is static on purpose: no shimmer, so nothing loops
// while Roomy's own thinking pose already says "working" (Figma "Skeleton v5"). VoiceOver skips it; the screen
// that shows skeletons owns one label for the wait.
import SwiftUI

struct SkeletonShape: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = Radius.row

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(RoomyColor.ringTrack)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }

    /// A line of text still to come: rounded ends, a fixed width.
    static func line(width: CGFloat, height: CGFloat = Layout.skeletonTextHeight) -> SkeletonShape {
        SkeletonShape(width: width, height: height, cornerRadius: height / 2)
    }
}

#Preview {
    HStack(spacing: Space.s16) {
        SkeletonShape.line(width: Layout.skeletonLineWidth)
        SkeletonShape(width: Layout.tilePhoto, height: Layout.tilePhoto)
        SkeletonShape(width: Layout.photoTileSize, height: Layout.photoTileSize, cornerRadius: Radius.control)
    }
    .padding()
}
