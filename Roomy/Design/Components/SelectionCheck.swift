// Why: the Photos-style circular checkmark, in one place. Over media it draws a white ring so it reads on
// any image; on a card it uses the secondary text colour. Each toggle crossfades the symbol and pops it from
// 80% to full size; with Reduce Motion it only fades. The haptic belongs to the tap that toggles, not to this view.
import SwiftUI

struct SelectionCheck: View {
    enum Surface {
        case media
        case card
    }

    let isSelected: Bool
    var surface: Surface = .media
    var size: CGFloat = 22

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Read here: the animator's content closure is Sendable and can't reach main-actor state.
        let popScale = reduceMotion ? 1 : Motion.popScale
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: size, weight: .semibold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(ringColor, fillColor)
            .contentTransition(.opacity)
            .animation(Motion.quick, value: isSelected)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: isSelected) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                MoveKeyframe(popScale)
                SpringKeyframe(CGFloat(1), spring: Motion.pop)
            }
            // The tile or row that owns the check carries the Selected trait; the icon itself is decoration.
            .accessibilityHidden(true)
    }

    private var ringColor: Color {
        if isSelected { return .white }
        return surface == .media ? .white : RoomyColor.textSecondary.opacity(0.5)
    }

    private var fillColor: Color {
        if isSelected { return RoomyColor.accent }
        return surface == .media ? Color.black.opacity(0.35) : .clear
    }
}
