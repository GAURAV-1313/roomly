// Why: per-group and per-month selection used the same quiet capsule as the one screen-level action, so a
// screen read as a column of repeated pills. This text-style checkbox (Figma "SelectToggle v5") has no fill:
// an empty circle, a filled check, or a minus when only some are in, with accent words beside it. It is a
// Button, not a Toggle, so VoiceOver reads its words and adds "Selected" when on. The glyph crossfades and the
// check pops, like the photo checks; with Reduce Motion it only fades. The target is at least 44 points tall.
import SwiftUI

struct SelectToggle: View {
    let title: String
    let state: SelectionState
    /// What VoiceOver reads instead of the short title, such as "Select extras in August 2026".
    var accessibilityLabel: String? = nil
    /// Read after the label, such as "7 of 11 selected".
    var accessibilityValue: String? = nil
    var accessibilityHint: String? = nil
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: Layout.inlineGap) {
                glyph
                // One line beside a summary; on its own row at accessibility sizes it may wrap.
                Text(title)
                    .contentTransition(.opacity)
                    .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: true)
            }
            .font(RoomyFont.footnoteSemibold)
            .foregroundStyle(RoomyColor.accent)
            .padding(.horizontal, Space.s4)
            .frame(minHeight: Layout.tapTarget)
            .contentShape(Rectangle())
            .animation(Motion.quick, value: state)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityValue(accessibilityValue ?? "")
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityAddTraits(state == .on ? .isSelected : [])
    }

    private var glyph: some View {
        // Read here: the animator's content closure is Sendable and can't reach main-actor state.
        let popScale = reduceMotion ? 1 : Motion.popScale
        return Image(systemName: symbol)
            .contentTransition(.opacity)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: state) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                MoveKeyframe(popScale)
                SpringKeyframe(CGFloat(1), spring: Motion.pop)
            }
            .accessibilityHidden(true)
    }

    private var symbol: String {
        switch state {
        case .off: "circle"
        case .mixed: "minus.circle.fill"
        case .on: "checkmark.circle.fill"
        }
    }
}
