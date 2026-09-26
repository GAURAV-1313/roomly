// Why: one value the merged card will hold, labelled, with a tag naming the card it comes from when that is not
// the card being kept, so the person sees exactly what the merge adds. The tag sits on the label line ("Email
// from card 2"), so the value keeps the full width and the tag stays one line (Figma "Fix 1"). At accessibility
// text sizes the tag moves under the label, still above the value.
import SwiftUI

struct MergedFieldRow: View {
    let label: String
    let value: MergedValue

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            labelLine
            Text(value.text)
                .font(RoomyFont.subheadline)
                .foregroundStyle(RoomyColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var labelLine: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s2))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Layout.inlineGap))
        return layout {
            Text(label).font(RoomyFont.caption).foregroundStyle(RoomyColor.textSecondary)
            if value.isAdded {
                ReasonChip(
                    text: "from card \(value.sourceCard.formatted())", tint: Route.duplicateContacts.categoryTintSoft,
                    size: .small)
            }
        }
    }
}
