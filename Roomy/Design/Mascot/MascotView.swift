// Why: the mascot is pure SwiftUI — no Lottie or Rive — so it ships with zero dependencies and animates by
// interpolating poses. Blinking runs in one task that stops when the view disappears and respects
// Reduce Motion.
import SwiftUI

struct MascotView: View {
    let mood: MascotMood
    var size: CGFloat = MascotSize.dashboard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blink = 0.0

    var body: some View {
        MascotCanvas(pose: .pose(for: mood), blink: blink)
            .frame(width: size, height: size)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: mood)
            .task(id: reduceMotion) { await blinkLoop() }
            // Roomy always sits beside text that says the same thing, so VoiceOver skips it.
            .accessibilityHidden(true)
    }

    private func blinkLoop() async {
        guard !reduceMotion else {
            blink = 0
            return
        }
        while !Task.isCancelled {
            // try? is deliberate: sleep only throws on cancellation, which the loop condition handles.
            try? await Task.sleep(for: .seconds(Double.random(in: 3.2...6.5)))
            guard !Task.isCancelled, MascotPose.pose(for: mood).eyeOpenness > 0.5 else { continue }
            withAnimation(.easeOut(duration: 0.08)) { blink = 1 }
            try? await Task.sleep(for: .milliseconds(90))
            withAnimation(.easeIn(duration: 0.10)) { blink = 0 }
        }
    }
}

/// `Animatable`, so SwiftUI interpolates the pose and the blink between frames.
struct MascotCanvas: View, Animatable {
    var pose: MascotPose
    var blink: Double

    var animatableData: AnimatablePair<AnimatableVector, Double> {
        get { AnimatablePair(pose.vector, blink) }
        set {
            pose.vector = newValue.first
            blink = newValue.second
        }
    }

    var body: some View {
        Canvas { context, size in
            MascotPainter(pose: pose, blink: blink, unit: min(size.width, size.height)).draw(in: &context, size: size)
        }
    }
}

#Preview("All moods") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Space.s16) {
        ForEach(MascotMood.allCases, id: \.self) { mood in
            VStack {
                MascotView(mood: mood)
                Text(mood.rawValue).font(RoomyFont.caption)
            }
        }
    }
    .padding()
    .background(RoomyColor.bg)
}
