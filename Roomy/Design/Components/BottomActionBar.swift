// Why: the floating glass capsule at the bottom of the screen. It is the one primary action on a screen,
// so it has one implementation and one iOS 17 fallback. When its title's count changes the digits roll.
import SwiftUI

struct BottomActionBar: View {
    let title: String
    var systemImage = "checklist"
    var isProminent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .contentTransition(.numericText())
                .animation(Motion.snappy, value: title)
                .font(RoomyFont.headline)
                .foregroundStyle(isProminent ? RoomyColor.onAccent : RoomyColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.s16)
                .padding(.vertical, Space.s8)
                .frame(maxWidth: .infinity)
                // A minimum, not a fixed height: at large text sizes the label wraps and the capsule grows.
                .frame(minHeight: Layout.bottomBarHeight)
                .roomyGlass(in: Capsule(), style: isProminent ? .prominent(RoomyColor.accent) : .regular)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Space.margin)
        .padding(.bottom, Space.s12)
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
