// Why: the floating glass capsule at the bottom of the screen, placed where every screen places it: the side
// margin in, just above the home indicator. It is the one primary action on a screen, so there is one capsule
// (`ActionCapsule`) with one iOS 17 fallback, and this is its standard position.
import SwiftUI

struct BottomActionBar: View {
    let title: String
    var systemImage = "checklist"
    var isProminent = false
    let action: () -> Void

    var body: some View {
        ActionCapsule(title: title, systemImage: systemImage, isProminent: isProminent, action: action)
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
