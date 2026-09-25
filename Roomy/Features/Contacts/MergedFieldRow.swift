// Why: one value the merged card will hold, labelled, with a tag when it comes from a card other than the one
// being kept, so the person sees exactly what the merge adds (Figma "MergedFieldRow v5"). At accessibility
// text sizes the tag moves under its value instead of squeezing it.
import SwiftUI

struct MergedFieldRow: View {
    let label: String
    let value: MergedValue

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s4))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s8))
        layout {
            VStack(alignment: .leading, spacing: Space.s2) {
                Text(label).font(RoomyFont.caption).foregroundStyle(RoomyColor.textSecondary)
                Text(value.text).font(RoomyFont.subheadline).foregroundStyle(RoomyColor.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if value.isAdded {
                ReasonChip(text: "from other card", tint: Route.duplicateContacts.categoryTintSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
