// Why: apps cannot empty Recently Deleted, so the result says exactly how to finish the job in Photos. It is the
// one amber element on the result, because it is how the space actually comes back. Numbers stay top-aligned
// while the steps wrap at large text sizes.
import SwiftUI

struct RecentlyDeletedSteps: View {
    private let steps = [
        "Open Photos and scroll to Utilities.",
        "Tap Recently Deleted and unlock it.",
        "Tap Select, then Delete All.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            header
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                stepRow(number: index + 1, text: step)
            }
            Text("Roomy checks free space again when you come back.")
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }

    private var header: some View {
        HStack(spacing: Space.s12) {
            Image(systemName: "trash")
                .font(RoomyFont.subheadlineSemibold)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundStyle(RoomyColor.warning)
                .frame(width: Layout.noticeIcon, height: Layout.noticeIcon)
                .background(
                    RoomyColor.warningSoft, in: RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous)
                )
                .accessibilityHidden(true)
            Text("Finish in Photos")
                .font(RoomyFont.headline)
                .foregroundStyle(RoomyColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: Space.s12) {
            Text("\(number)")
                .font(RoomyFont.footnoteSemibold)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundStyle(RoomyColor.accent)
                .frame(width: Layout.stepNumber, height: Layout.stepNumber)
                .background(RoomyColor.accentTint, in: Circle())
            Text(text)
                .font(RoomyFont.subheadline)
                .foregroundStyle(RoomyColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, Space.s4)
        .accessibilityElement(children: .combine)
    }
}
