// Why: three small capsules say where the person is (Figma "PageDots v5"). They are not a TabView page control,
// because swiping past Permissions must not be possible while Continue waits for Photos. The current dot widens
// and turns navy; with Reduce Motion only its colour fades and the width changes at once. VoiceOver hears
// "Page 2 of 3" once, not three dots.
import SwiftUI

struct OnboardingPageDots: View {
    let current: OnboardingPage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Space.s8) {
            ForEach(OnboardingPage.allCases, id: \.self) { page in
                let isCurrent = page == current
                Capsule()
                    .fill(isCurrent ? RoomyColor.accent : RoomyColor.ringUsed)
                    .animation(reduceMotion ? Motion.quick : Motion.snappy, value: current)
                    .frame(width: isCurrent ? Layout.pageDotCurrent : Layout.pageDot, height: Layout.pageDot)
                    .animation(reduceMotion ? nil : Motion.snappy, value: current)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current.rawValue + 1) of \(OnboardingPage.allCases.count)")
    }
}
