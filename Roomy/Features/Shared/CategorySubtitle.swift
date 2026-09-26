// Why: the tinted summary card above each category list was tall and pushed the first group down (Figma "Fix 5
// · C"). The numbers now sit in one line under the large title, with the category's glyph as the only colour, so
// the list starts right under it. `navigationSubtitle` exists only from iOS 26, so this is a row of the list; it
// wraps, and its glyph scales with the text.
import SwiftUI

struct CategorySubtitle: View {
    let route: Route
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s4) {
            Image(systemName: systemImage)
                .foregroundStyle(route.categoryTint)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(RoomyColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.numericText())
                .animation(Motion.snappy, value: text)
        }
        .font(RoomyFont.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Space.s4)
    }
}
