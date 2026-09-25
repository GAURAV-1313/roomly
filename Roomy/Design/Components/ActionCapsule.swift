// Why: the floating glass capsule that is a screen's one primary action (Figma "ReviewCapsule v5"). It can fill
// from its leading edge with real progress, so a running task shows one moving bar in the place the person
// would stop it. The fill sits inside the glass, clipped to the capsule. Only the capsule is drawn here; where
// it sits on screen is up to the caller. The icon swaps with a symbol replace, the digits of a count roll.
import SwiftUI

struct ActionCapsule: View {
    let title: String
    var systemImage = "checklist"
    var isProminent = false
    /// How far the capsule is filled, from 0 to 1; nil draws no fill.
    var progress: Double? = nil
    /// Read by VoiceOver after the title, such as "21%".
    var accessibilityValue: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title).contentTransition(.numericText())
            } icon: {
                Image(systemName: systemImage).contentTransition(.symbolEffect(.replace))
            }
            .animation(Motion.snappy, value: title)
            .font(RoomyFont.headline)
            .foregroundStyle(isProminent ? RoomyColor.onAccent : RoomyColor.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.s16)
            .padding(.vertical, Space.s8)
            .frame(maxWidth: .infinity)
            // A minimum, not a fixed height: at large text sizes the label wraps and the capsule grows.
            .frame(minHeight: Layout.bottomBarHeight)
            .background(alignment: .leading) { fill }
            .clipShape(Capsule())
            .roomyGlass(in: Capsule(), style: isProminent ? .prominent(RoomyColor.accent) : .regular)
        }
        .buttonStyle(.plain)
        .accessibilityValue(accessibilityValue ?? "")
    }

    @ViewBuilder
    private var fill: some View {
        if let progress {
            GeometryReader { proxy in
                RoomyColor.accentTint
                    .frame(width: proxy.size.width * progress)
            }
            .animation(Motion.progress, value: progress)
            .transition(.opacity)
            .accessibilityHidden(true)
        }
    }
}
