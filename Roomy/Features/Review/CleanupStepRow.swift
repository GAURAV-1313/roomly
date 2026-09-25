// Why: one step of a running cleanup, with an indicator that says its state without colour alone: a check when
// done, a spinner while running, an empty circle when next. The indicator stays top-aligned while the words wrap.
// When a step finishes its spinner gives way to the check drawing in and its words turn secondary; with Reduce
// Motion the swap is instant.
import SwiftUI

struct CleanupStepRow: View {
    let row: CleanupProgress.Row

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: Space.s12) {
            indicator
                .frame(width: Layout.stepIndicator, height: Layout.stepIndicator)
                .accessibilityHidden(true)
            Text(row.step.message)
                .font(RoomyFont.body)
                .foregroundStyle(row.state == .active ? RoomyColor.textPrimary : RoomyColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Space.s8)
        .animation(reduceMotion ? nil : Motion.quick, value: row.state)
        .accessibilityElement(children: .combine)
        .accessibilityValue(stateLabel)
    }

    @ViewBuilder
    private var indicator: some View {
        switch row.state {
        case .done:
            Image(systemName: "checkmark")
                .font(RoomyFont.footnoteSemibold)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundStyle(RoomyColor.success)
                .transition(.symbolEffect(.appear))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoomyColor.successSoft, in: Circle())
        case .active:
            ProgressView()
                .controlSize(.small)
                .tint(RoomyColor.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoomyColor.accentTint, in: Circle())
                .transition(.opacity)
        case .upcoming:
            Circle().fill(RoomyColor.chip)
        }
    }

    private var stateLabel: String {
        switch row.state {
        case .done: "Done"
        case .active: "In progress"
        case .upcoming: "Next"
        }
    }
}
