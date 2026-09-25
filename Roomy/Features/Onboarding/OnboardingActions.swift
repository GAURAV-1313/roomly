// Why: there is one Continue, pinned at the bottom, and it never moves: only the page content slides. Every row
// here — the dots, the "Allow Photos to continue" note, Continue and Not now — keeps its place on every page and
// only fades where it does not apply. On Welcome, Continue fades in with the truths but is tappable from the
// first frame: a catcher under it takes the tap while the button is still invisible. On Permissions it waits for
// Photos, dimmed, with a note that says why, and lights up the moment Photos can be used (motion row 3).
import SwiftUI

struct OnboardingActions: View {
    /// Continue stays visible but dimmed while it waits for Photos.
    private static let waitingOpacity = 0.4

    let page: OnboardingPage
    let canUsePhotos: Bool
    /// On Welcome, whether the truths — and so Continue — have faded in yet.
    let isWelcomeTextShown: Bool
    let onContinue: () -> Void
    let onNotNow: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isWaitingForPhotos: Bool { page == .permissions && !canUsePhotos }

    var body: some View {
        VStack(spacing: Space.s8) {
            OnboardingPageDots(current: page).padding(.bottom, Space.s4)
            Text("Allow Photos to continue")
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
                .shown(isWaitingForPhotos)
                .animation(Motion.quick, value: isWaitingForPhotos)
            continueButton
            Button("Not now", action: onNotNow)
                .buttonStyle(.roomyText)
                .shown(page.offersNotNow)
                .animation(Motion.quick, value: page)
        }
        .padding(.horizontal, Space.margin)
        .padding(.top, Space.s8)
        .padding(.bottom, Space.s12)
    }

    private var continueButton: some View {
        ZStack {
            // Takes the tap while the button itself is still invisible; hidden views receive no touches.
            Capsule()
                .fill(.clear)
                .contentShape(Capsule())
                .onTapGesture(perform: onContinue)
                .allowsHitTesting(page == .welcome)
                .accessibilityHidden(true)
            Button("Continue", action: onContinue)
                .buttonStyle(.roomyPrimary)
                .disabled(isWaitingForPhotos)
                .opacity(continueOpacity)
                .animation(continueAnimation, value: continueOpacity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var continueOpacity: Double {
        if page == .welcome && !isWelcomeTextShown { return 0 }
        return isWaitingForPhotos ? Self.waitingOpacity : 1
    }

    /// On Welcome it rises with the truths; elsewhere a quick fade, which is also safe with Reduce Motion.
    private var continueAnimation: Animation? {
        if page == .welcome && !reduceMotion { return Motion.truthRise }
        return Motion.quick
    }
}
