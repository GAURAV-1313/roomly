// Why: the one switch between the app's three roots — onboarding, the launch intro, the dashboard — each fading into
// the next as one root crossfade (motion row 5). The rule is `LaunchRoot`; this view only holds its inputs. Whether
// the intro is due is read once, when the launch begins, so finishing onboarding never plays it. Reduce Motion clears
// it — on the first appearance or whenever it is turned on — so turning Reduce Motion off later in the session can
// never bring the intro back over the dashboard and its navigation.
import SwiftUI

struct AppRoot: View {
    @AppStorage(LaunchRoot.didOnboardKey) private var didOnboard = false
    @State private var isIntroDue = UserDefaults.standard.bool(forKey: LaunchRoot.didOnboardKey)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch LaunchRoot(didOnboard: didOnboard, isIntroDue: isIntroDue, reduceMotion: reduceMotion) {
            // Onboarding animates the flag itself, so it crossfades into the dashboard.
            case .onboarding: OnboardingView { didOnboard = true }.transition(.opacity)
            case .intro: LaunchIntroView(onFinish: finishIntro).transition(.opacity)
            case .dashboard: DashboardView().transition(.opacity)
            }
        }
        .onAppear {
            if reduceMotion {
                isIntroDue = false
            }
        }
        .onChange(of: reduceMotion) { _, isReduced in
            if isReduced {
                isIntroDue = false
            }
        }
    }

    private func finishIntro() {
        guard isIntroDue else { return }
        withAnimation(Motion.introHandOff) { isIntroDue = false }
    }
}
