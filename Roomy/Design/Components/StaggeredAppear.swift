// Why: the dashboard's first appearance reads top to bottom — card, notice, heading, tiles — each block rising a
// little as it fades in, a moment after the one above. The parent owns one `isShown` flag it flips once, so the
// sequence plays on the first appearance only and never when the person comes back. With Reduce Motion every
// block fades in together with no offset.
import SwiftUI

struct StaggeredAppear: ViewModifier {
    /// The block's place in the sequence, from the top.
    let index: Int
    let isShown: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : Motion.rise)
            .animation(animation, value: isShown)
    }

    private var animation: Animation {
        reduceMotion ? Motion.quick : Motion.standard.delay(Motion.staggerDelay(for: index))
    }
}

extension View {
    /// Fades the view in, rising from below, as block `index` of a sequence the parent starts with `isShown`.
    func staggeredAppear(_ index: Int, isShown: Bool) -> some View {
        modifier(StaggeredAppear(index: index, isShown: isShown))
    }
}
