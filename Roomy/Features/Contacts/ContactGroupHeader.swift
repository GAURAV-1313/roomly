// Why: device test — "the number of cards isn't visible, the pill isn't aligned". The name and the reason chip
// share one row on the first text baseline; the chip never wraps, so a long name wraps instead. Under them a
// "2 cards → 1" badge says what the merge does. At accessibility sizes the chip moves under the name, then the
// badge. VoiceOver reads the header as one sentence: "Anika Mehta, same number, 2 cards merge into 1".
import SwiftUI

struct ContactGroupHeader: View {
    let name: String
    let reason: String
    let cardCount: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: Space.s12) {
            avatar
            VStack(alignment: .leading, spacing: Layout.inlineGap) {
                nameRow
                CountBadge(count: cardCount.counted("card"), result: "→ 1")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding([.leading, .top], Space.s4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayName), \(reason.lowercased()), \(cardCount.counted("card")) merge into 1")
        .accessibilityAddTraits(.isHeader)
    }

    private var displayName: String { name.isEmpty ? "No name" : name }

    @ViewBuilder
    private var nameRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Space.s4) {
                nameText
                chip
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: Space.s8) {
                nameText.frame(maxWidth: .infinity, alignment: .leading)
                chip
            }
        }
    }

    private var nameText: some View {
        Text(displayName)
            .font(RoomyFont.headline)
            .foregroundStyle(RoomyColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var chip: some View {
        ReasonChip(text: reason, tint: Route.duplicateContacts.categoryTintSoft)
    }

    private var avatar: some View {
        Text(initials)
            .font(RoomyFont.headline)
            .foregroundStyle(Route.duplicateContacts.categoryTint)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .frame(width: Layout.tapTarget, height: Layout.tapTarget)
            .background(Route.duplicateContacts.categoryTintSoft, in: Circle())
    }

    private var initials: String {
        let words = name.split(separator: " ").prefix(2)
        let letters = words.compactMap(\.first).map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }
}
