// Why: when a screen's capsule is taken by a more important action, a second one waits beside it as a round
// glass button the capsule's height (Figma "Round cancel button + ring"). It can carry a progress ring, so a
// task that runs in the background still shows how far it got in the place the person would stop it.
import SwiftUI

struct RoundActionButton: View {
    let title: String
    let systemImage: String
    /// How far the ring is drawn, from 0 to 1; nil draws no ring.
    var progress: Double? = nil
    /// Read by VoiceOver after the title, such as "21%".
    var accessibilityValue: String? = nil
    /// Whether a ring's track shows even before there is progress to draw on it.
    var showsTrack = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(RoomyFont.headline)
                // The circle has a fixed size, so the glyph stops growing where it would spill out.
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(RoomyColor.textPrimary)
                .frame(width: Layout.bottomBarHeight, height: Layout.bottomBarHeight)
                .overlay { ring }
                .roomyGlass(in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue ?? "")
    }

    @ViewBuilder
    private var ring: some View {
        if showsTrack || progress != nil {
            ZStack {
                Circle().stroke(RoomyColor.ringTrack, lineWidth: Layout.roundActionRingLine)
                Circle()
                    .trim(from: 0, to: progress ?? 0)
                    .stroke(
                        RoomyColor.accent,
                        style: StrokeStyle(lineWidth: Layout.roundActionRingLine, lineCap: .round)
                    )
                    // The ring starts at twelve o'clock and runs clockwise, like the system's.
                    .rotationEffect(.degrees(-90))
                    .animation(Motion.progress, value: progress)
            }
            .padding(Layout.roundActionRingInset)
            .transition(.opacity)
            .accessibilityHidden(true)
        }
    }
}
