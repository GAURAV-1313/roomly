// Why: device test — "only one card is visible". Each card being merged gets its own numbered row: its name,
// "kept" on the card that stays, and its phones and emails, with the value it shares with another card tinted,
// so the person sees which cards are one person and why. The numbers are the ones the merged values' "from card
// 2" tags refer to. VoiceOver reads one element per card; the number circle is decoration, capped at .xLarge.
import SwiftUI

struct MemberCardRow: View {
    let member: MergeMember

    var body: some View {
        HStack(alignment: .top, spacing: Layout.memberNumberGap) {
            number
            VStack(alignment: .leading, spacing: 0) {
                nameRow
                if !member.values.isEmpty {
                    Text(values)
                        .font(RoomyFont.footnote)
                        .foregroundStyle(RoomyColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Space.s8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var name: String { member.name.isEmpty ? "No name" : member.name }

    private var number: some View {
        Text(member.number.formatted())
            .font(RoomyFont.captionSemibold)
            .foregroundStyle(RoomyColor.textSecondary)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .frame(width: Layout.memberNumber, height: Layout.memberNumber)
            .background(RoomyColor.chip, in: Circle())
    }

    private var nameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.inlineGap) {
            Text(name)
                .font(RoomyFont.subheadlineSemibold)
                .foregroundStyle(RoomyColor.textPrimary)
            if member.isKept {
                Text("kept")
                    .font(RoomyFont.caption)
                    .foregroundStyle(RoomyColor.textSecondary)
            }
        }
    }

    /// Phones and emails joined with " · ", the shared ones tinted and semibold.
    private var values: AttributedString {
        var text = AttributedString()
        for (index, value) in member.values.enumerated() {
            if index > 0 {
                text.append(AttributedString(" · "))
            }
            var part = AttributedString(value.text)
            if value.isShared {
                part.foregroundColor = Route.duplicateContacts.categoryTint
                part.font = RoomyFont.footnoteSemibold
            }
            text.append(part)
        }
        return text
    }

    /// "Card 1, kept, Anika Mehta, +91 98200 11223, +91 22 4000 1234".
    private var accessibilityText: String {
        let kept: [String] = member.isKept ? ["kept"] : []
        let parts = ["Card \(member.number.formatted())"] + kept + [name] + member.values.map(\.text)
        return parts.joined(separator: ", ")
    }
}
