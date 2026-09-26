// Why: the floating glass capsules at the bottom of the screen, placed where every screen places them: the side
// margin in, just above the home indicator. The primary capsule (`ActionCapsule`) is the screen's one primary
// action. A category screen can put its bulk action beside it on the leading side (Figma "Fix 5 · C"), so
// selecting everything and reviewing it are two taps in the same thumb zone. With both, the leading capsule
// keeps its own width and the primary takes the rest; alone, either spans the bar. At accessibility text sizes
// the two stack, the bulk action above. The primary rises in beside the other; with Reduce Motion it only fades.
import SwiftUI

/// One capsule in the bottom bar.
struct BottomBarAction {
    let title: String
    var systemImage = "checklist"
    var isProminent = false
    /// What VoiceOver reads when the visible title is shortened, such as "Review 8 items · 11.9 MB".
    var accessibilityLabel: String? = nil
    let perform: () -> Void
}

struct BottomActionBar: View {
    var leading: BottomBarAction? = nil
    var primary: BottomBarAction? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glass

    private var isStacked: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(spacing: Space.s8))
            : AnyLayout(HStackLayout(spacing: Space.s8))
        RoomyGlassContainer(spacing: Space.s8) {
            layout {
                if let leading {
                    capsule(leading)
                        .fixedSize(horizontal: primary != nil && !isStacked, vertical: false)
                        .roomyGlassID("leading", in: reduceMotion ? nil : glass)
                }
                if let primary {
                    capsule(primary)
                        .roomyGlassID("primary", in: reduceMotion ? nil : glass)
                        .transition(primaryTransition)
                }
            }
        }
        .padding(.horizontal, Space.margin)
        .padding(.bottom, Space.s12)
        .animation(reduceMotion ? Motion.quick : Motion.standard, value: primary == nil)
        .animation(reduceMotion ? Motion.quick : Motion.standard, value: leading == nil)
    }

    private func capsule(_ action: BottomBarAction) -> some View {
        ActionCapsule(
            title: action.title, systemImage: action.systemImage, isProminent: action.isProminent,
            action: action.perform
        )
        .accessibilityLabel(action.accessibilityLabel ?? action.title)
    }

    /// Beside a bulk action the primary grows out of the trailing side; alone it rises from the bottom.
    private var primaryTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        let edge: Edge = leading == nil || isStacked ? .bottom : .trailing
        return .move(edge: edge).combined(with: .opacity)
    }
}

extension View {
    /// Hosts a floating bottom bar: as an iOS 26 safe-area bar, so scroll content gets the soft edge effect
    /// under it, and as a safe-area inset below iOS 26.
    @ViewBuilder
    func bottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .bottom, content: bar)
        } else {
            safeAreaInset(edge: .bottom, content: bar)
        }
    }
}
