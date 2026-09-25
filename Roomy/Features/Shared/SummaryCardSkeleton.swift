// Why: while a category is still being read, its screen already has its final shape: the summary card first,
// in the category's colour, with skeleton lines where the total and what it counts will be. When the numbers
// arrive the real card fades in over the same frame, so nothing jumps.
import SwiftUI

struct SummaryCardSkeleton: View {
    let route: Route

    var body: some View {
        HStack(spacing: Space.s12) {
            SkeletonShape(width: Layout.tapTarget, height: Layout.tapTarget)
            VStack(alignment: .leading, spacing: Space.s8) {
                SkeletonShape.line(width: Layout.skeletonTitleWidth, height: Layout.skeletonTitleHeight)
                SkeletonShape.line(width: Layout.skeletonDetailWidth)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, Space.s12)
        .padding(.trailing, Space.s16)
        .padding(.vertical, Space.s12)
        .background(route.categoryTintSoft, in: RoundedRectangle(cornerRadius: Radius.well, style: .continuous))
        .padding(Layout.tileInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }
}

extension View {
    /// A screen of skeletons is one VoiceOver element that says what the wait is for.
    func loadingScreen(_ label: String) -> some View {
        self
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }
}
