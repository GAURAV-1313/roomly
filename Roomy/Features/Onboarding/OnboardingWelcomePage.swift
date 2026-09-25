// Why: the first page tells the whole product in about two seconds, once: a nearly full phone gives one short red
// signal, is cleaned down to calm green as Roomy lands, and the promise and three truths rise in. One stored
// `.task` plays the beats from `WelcomeScene`; it is keyed to `isSettled`, so a tap, Skip or Continue cancels it
// and lands on the rest pose, and leaving the page cancels it too. Nothing here ever delays a tap. With Reduce
// Motion the parent shows the rest pose at once and the task only records it.
import SwiftUI

struct OnboardingWelcomePage: View {
    /// What the screen shows; the parent owns it because Continue fades in with the truths.
    @Binding var scene: WelcomeScene
    let isSettled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Space.s24) {
            WelcomeStage(scene: scene)
            VStack(spacing: Space.s20) {
                promise
                truths
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .task(id: isSettled) { await play() }
    }

    private var promise: some View {
        VStack(spacing: Space.s8) {
            Text("Make room, safely")
                .font(RoomyFont.title1)
                .foregroundStyle(RoomyColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("Find what can go. You decide what leaves.")
                .font(RoomyFont.body)
                .foregroundStyle(RoomyColor.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .opacity(scene.isPromiseShown ? 1 : 0)
        .offset(y: scene.isPromiseShown || reduceMotion ? 0 : Motion.promiseOffset)
        .animation(reduceMotion ? nil : Motion.promiseRise, value: scene.isPromiseShown)
    }

    /// Inline while they fit; one per line at large text sizes.
    private var truths: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.s16) { truthItems }
            VStack(spacing: Space.s8) { truthItems }
        }
    }

    @ViewBuilder
    private var truthItems: some View {
        truth(0, "On this phone", systemImage: "magnifyingglass")
        truth(1, "Nothing leaves it", systemImage: "lock.fill")
        truth(2, "You decide", systemImage: "checklist")
    }

    private func truth(_ index: Int, _ text: String, systemImage: String) -> some View {
        HStack(spacing: Layout.truthSpacing) {
            Image(systemName: systemImage).foregroundStyle(RoomyColor.accent).accessibilityHidden(true)
            Text(text).foregroundStyle(RoomyColor.textSecondary)
        }
        .font(RoomyFont.footnoteSemibold)
        .fixedSize()
        .opacity(scene.areTruthsShown ? 1 : 0)
        .offset(y: scene.areTruthsShown || reduceMotion ? 0 : Motion.truthOffset)
        .animation(
            reduceMotion ? nil : Motion.truthRise.delay(Double(index) * Motion.truthStagger),
            value: scene.areTruthsShown)
    }

    /// Plays the beats at their times. Cancelled when `isSettled` changes or the page goes away; a cancelled run
    /// writes nothing more.
    private func play() async {
        if isSettled || reduceMotion {
            withAnimation(reduceMotion ? nil : Motion.quick) { scene.settle() }
            return
        }
        // A run that was interrupted part-way never restarts the story; it lands on the rest pose.
        guard scene == .start else {
            scene.settle()
            return
        }
        let clock = ContinuousClock()
        let start = clock.now
        for beat in WelcomeScene.beats {
            do {
                try await clock.sleep(until: start + beat.start)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            withAnimation(animation(for: beat)) { scene.apply(beat) }
        }
    }

    /// The capsule's changes are animated here; the drop, the text and Roomy's mood animate themselves.
    private func animation(for beat: WelcomeBeat) -> Animation? {
        switch beat {
        case .signal: Motion.signalWarm
        case .sweep: Motion.sweep
        case .drop, .promise, .truths, .pleased: nil
        }
    }
}
