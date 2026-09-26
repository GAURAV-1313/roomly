// Why: while a category is still being read, its screen already has its final shape: a skeleton line where the
// numbers under the title will be, then the list's own skeletons. When the numbers arrive the real line fades in
// over the same place, so nothing jumps, and no count is shown before it is real.
import SwiftUI

struct CategorySubtitleSkeleton: View {
    var body: some View {
        SkeletonShape.line(width: Layout.skeletonDetailWidth)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Space.s4)
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
