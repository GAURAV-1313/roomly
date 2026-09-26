// Why: a short, calm opening on every launch after onboarding — the Welcome stage on its wash, playing the beats in
// `LaunchIntroBeat` — so the app starts with its promise in motion while the scan already runs. It reuses the
// Welcome stage, capsule and wash as they are, without the haptic: a buzz on every launch would be noise. One stored
// task plays the beats; a tap cancels it and hands off at once, and leaving cancels it too, so a cancelled run
// writes nothing more. Reduce Motion never reaches this view: `LaunchRoot` skips it.
import SwiftUI

struct LaunchIntroView: View {
    let onFinish: () -> Void

    @State private var scene = WelcomeScene.start
    @State private var playback: Task<Void, Never>?

    var body: some View {
        WelcomeStage(scene: scene, playsHaptic: false)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { WelcomeWash().ignoresSafeArea() }
            .contentShape(Rectangle())
            .onTapGesture(perform: skip)
            .accessibilityElement()
            .accessibilityLabel("Opening Roomy")
            .accessibilityHint("Skips the intro")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { skip() }
            .onAppear(perform: play)
            .onDisappear { playback?.cancel() }
    }

    private func play() {
        guard playback == nil else { return }
        playback = Task { await runBeats() }
    }

    private func skip() {
        playback?.cancel()
        onFinish()
    }

    /// Plays the beats at their times, then hands off. A cancelled run returns without touching the scene.
    private func runBeats() async {
        let clock = ContinuousClock()
        let start = clock.now
        for beat in LaunchIntroBeat.beats {
            do {
                try await clock.sleep(until: start + beat.start)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            guard let welcomeBeat = beat.welcomeBeat else {
                onFinish()
                return
            }
            withAnimation(animation(for: welcomeBeat)) { scene.apply(welcomeBeat) }
        }
    }

    /// The capsule's changes are animated here; the drop, the shake and Roomy's mood animate themselves.
    private func animation(for beat: WelcomeBeat) -> Animation? {
        switch beat {
        case .signal: Motion.signalWarm
        case .sweep: Motion.sweep
        case .drop, .promise, .truths, .pleased: nil
        }
    }
}

#Preview {
    LaunchIntroView {}
}
