// Why: the top row (Figma "OnboardingNav v5") holds Back, a glass circle and the only glass on these pages, and
// Skip, a text button. Each keeps its place on every page and only fades where it does not apply, so nothing
// jumps as the pages slide beneath it.
import SwiftUI

struct OnboardingNavBar: View {
    let page: OnboardingPage
    let onBack: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(RoomyFont.headline)
                    // The circle has a fixed size, so its glyph stops growing where it would spill out.
                    .dynamicTypeSize(...DynamicTypeSize.xLarge)
                    .foregroundStyle(RoomyColor.textPrimary)
                    .frame(width: Layout.tapTarget, height: Layout.tapTarget)
                    .roomyGlass(in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .shown(page.canGoBack)
            Spacer()
            Button("Skip", action: onSkip)
                .buttonStyle(.roomyText)
                .fixedSize()
                .shown(page.canSkip)
        }
        .padding(.horizontal, Space.margin)
        .animation(Motion.quick, value: page)
    }
}

extension View {
    /// Keeps the view's place but hides it from sight, touch and VoiceOver when it does not apply.
    func shown(_ isShown: Bool) -> some View {
        opacity(isShown ? 1 : 0)
            .allowsHitTesting(isShown)
            .accessibilityHidden(!isShown)
    }
}
