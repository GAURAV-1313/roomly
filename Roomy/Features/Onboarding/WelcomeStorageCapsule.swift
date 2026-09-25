// Why: the Welcome capsule (Figma "StorageCapsule v5") tells a story, not a measurement, so it has a caption and
// no number and VoiceOver skips it. The fill is navy when full, warms into red toward its full end for the signal,
// and settles into green once cleaned down. Red lives only in the fill, briefly, and never at rest; there is no
// border. Each colour is its own layer whose opacity animates, so any stage change crossfades smoothly.
import SwiftUI

struct WelcomeStorageCapsule: View {
    let stage: WelcomeCapsuleStage

    var body: some View {
        VStack(spacing: Space.s8) {
            Text("iPhone storage")
                .font(RoomyFont.caption)
                .foregroundStyle(RoomyColor.textSecondary)
            track
        }
        .accessibilityHidden(true)
    }

    private var track: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(RoomyColor.ringTrack)
                .overlay(alignment: .leading) {
                    fill.frame(width: proxy.size.width * stage.fill)
                }
        }
        .frame(width: Layout.capsuleWidth, height: Layout.capsuleHeight)
    }

    /// Navy underneath; the red signal and the calm green fade over it.
    private var fill: some View {
        ZStack {
            RoomyColor.accent
            LinearGradient(
                stops: [
                    .init(color: RoomyColor.accent, location: 0),
                    .init(color: RoomyColor.destructive, location: Self.redStart),
                    .init(color: RoomyColor.destructive, location: 1),
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .opacity(stage.redAmount)
            RoomyColor.success.opacity(stage.greenAmount)
        }
        .clipShape(Capsule())
    }

    /// Where the signal's red is at full strength, from the fill's start (Figma "Stage=signal").
    private static let redStart = 0.45
}

#Preview {
    VStack(spacing: Space.s24) {
        WelcomeStorageCapsule(stage: .full)
        WelcomeStorageCapsule(stage: .signal)
        WelcomeStorageCapsule(stage: .low)
    }
    .padding()
    .background(RoomyColor.bg)
}
