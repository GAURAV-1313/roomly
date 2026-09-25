// Why: three pages — Welcome, How it works, Permissions — then the dashboard itself, with the first scan starting.
// The pages sit side by side and the row slides, so a page always comes in from the edge it lives on and Back
// reverses it (motion row 1); with Reduce Motion they only crossfade. The top row and the pinned Continue never
// move with them. Photos is required: Continue waits for it, Skip stops at Permissions, and "Not now" is the only
// way past without it. The hand-off is one root crossfade (motion row 5); the dashboard then fades up on its own.
import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onContinue: () -> Void

    @State private var page = OnboardingPage.welcome
    @State private var welcome = WelcomeScene.start
    /// Set by a tap, Skip or Continue on Welcome; from then on Welcome shows its rest pose.
    @State private var isWelcomeSettled = false

    /// With Reduce Motion, Welcome is drawn in its calm rest pose from the first frame.
    private var welcomeScene: Binding<WelcomeScene> {
        Binding(get: { reduceMotion ? .rest : welcome }, set: { welcome = $0 })
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(OnboardingPage.allCases, id: \.self) { item in
                    pageView(item, height: proxy.size.height).frame(width: proxy.size.width)
                }
            }
            .offset(x: -CGFloat(page.rawValue) * proxy.size.width)
            .animation(reduceMotion ? nil : Motion.standard, value: page)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            OnboardingNavBar(page: page, onBack: goBack, onSkip: skip)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            OnboardingActions(
                page: page, canUsePhotos: app.photoAccess.state.canUse,
                isWelcomeTextShown: welcomeScene.wrappedValue.areTruthsShown,
                onContinue: continueTapped, onNotNow: handOff
            )
            .background(RoomyColor.bg.ignoresSafeArea())
        }
        .background(RoomyColor.bg.ignoresSafeArea())
    }

    private func pageView(_ item: OnboardingPage, height: CGFloat) -> some View {
        let isCurrent = item == page
        return ScrollView {
            pageContent(item)
                .padding(.horizontal, Space.margin)
                .padding(.vertical, Space.s12)
                .frame(maxWidth: .infinity, minHeight: height, alignment: item == .welcome ? .center : .top)
                .contentShape(Rectangle())
                .onTapGesture { if item == .welcome { settleWelcome() } }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { pageBackground(item).ignoresSafeArea() }
        .opacity(isCurrent ? 1 : 0)
        .animation(reduceMotion ? Motion.quick : Motion.standard, value: page)
        .allowsHitTesting(isCurrent)
        .accessibilityHidden(!isCurrent)
    }

    @ViewBuilder
    private func pageContent(_ item: OnboardingPage) -> some View {
        switch item {
        case .welcome: OnboardingWelcomePage(scene: welcomeScene, isSettled: isWelcomeSettled)
        case .howItWorks: OnboardingHowItWorksPage()
        case .permissions: OnboardingPermissionsPage()
        }
    }

    @ViewBuilder
    private func pageBackground(_ item: OnboardingPage) -> some View {
        if item == .welcome {
            WelcomeWash()
        } else {
            RoomyColor.bg
        }
    }

    private func continueTapped() {
        if let next = page.next {
            Haptics.tap()
            settleWelcome()
            page = next
        } else if app.photoAccess.state.canUse {
            Haptics.tap()
            handOff()
        }
    }

    private func goBack() {
        guard let previous = page.previous else { return }
        page = previous
    }

    private func skip() {
        settleWelcome()
        page = page.skipTarget
    }

    /// Any tap on Welcome, or leaving it, lands the story on its rest pose; it never replays.
    private func settleWelcome() {
        guard page == .welcome else { return }
        isWelcomeSettled = true
    }

    /// Onboarding fades out as a whole — Continue with it — while the dashboard fades up.
    private func handOff() {
        withAnimation(reduceMotion ? Motion.quick : Motion.handOff) { onContinue() }
    }
}

#Preview {
    OnboardingView {}.environment(AppState())
}
