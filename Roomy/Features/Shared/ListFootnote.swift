// Why: the honest notes that lived in the summary card (photos Roomy couldn't compare, what a merge carries
// over) must not vanish with it. They close the list as one small footnote with an info glyph, where they are
// read after the items they qualify and never push those items down.
import SwiftUI

struct ListFootnote: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s8) {
            Image(systemName: "info.circle").accessibilityHidden(true)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(RoomyFont.footnote)
        .foregroundStyle(RoomyColor.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Space.s8)
    }
}
