// Why: a filter is a chip you turn on, not a settings row (Figma "Fix 5 · C": the "Over 500 MB" switch row
// became a chip under the title). Off it is the neutral chip; on it fills with the accent and shows a check, so
// the state never rests on colour alone. VoiceOver reads it as a selected button. The chip is short, but its
// tap area reaches the full 44 points.
import SwiftUI

struct FilterChip: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            Haptics.tap()
            isOn.toggle()
        } label: {
            HStack(spacing: Space.s4) {
                if isOn {
                    Image(systemName: "checkmark").accessibilityHidden(true)
                }
                Text(title)
            }
            .font(RoomyFont.footnoteSemibold)
            .foregroundStyle(isOn ? RoomyColor.onAccent : RoomyColor.textPrimary)
            .padding(.horizontal, Space.s12)
            .padding(.vertical, Space.s4)
            .background(isOn ? RoomyColor.accent : RoomyColor.chip, in: Capsule())
            .frame(minHeight: Layout.tapTarget)
            .contentShape(Rectangle())
            .animation(Motion.quick, value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
