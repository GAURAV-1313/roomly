// Why: a merge is approved by reading both what goes in and what comes out. Each group lists the cards being
// folded together, numbered, with the values that tie them marked (device test: "only one card is visible"),
// then the card it will become — every phone and email, each added value naming the card it comes from — and
// whether it moves data between accounts, before anything is selected. Selected groups get the accent ring and
// a prominent button, like selected videos. Figma "Fix 1 · Duplicate Contacts".
import SwiftUI

struct ContactGroupCard: View {
    let group: ContactGroup
    let preview: MergePreview
    let isSelected: Bool
    let onToggle: () -> Void

    /// Whether the cards past the first three show; UI-only, kept while the card is on screen.
    @State private var isShowingAllMembers = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            ContactGroupHeader(name: preview.name, reason: group.reason.label, cardCount: group.members.count)
            memberCards
            afterMerging
            selectButton
        }
        .padding(Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
        .selectedRing(isSelected)
    }

    private var memberCards: some View {
        let list = MemberList(members: preview.members, isExpanded: isShowingAllMembers)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(list.visible.enumerated()), id: \.element.number) { index, member in
                if index > 0 {
                    separator
                }
                MemberCardRow(member: member)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
            if let more = list.moreLabel {
                separator
                Button(more) {
                    withAnimation(reduceMotion ? Motion.quick : Motion.disclose) { isShowingAllMembers = true }
                }
                .font(RoomyFont.footnoteSemibold)
                .foregroundStyle(RoomyColor.accent)
                .frame(minHeight: Layout.tapTarget)
                .padding(.leading, Layout.memberNumber + Layout.memberNumberGap)
            }
        }
        .padding(.horizontal, Space.s12)
        .padding(.vertical, Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoomyColor.nested, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }

    /// Starts past the number circle, so the numbers read as one column.
    private var separator: some View {
        RoomyColor.separator
            .frame(height: Layout.hairline)
            .padding(.leading, Layout.memberNumber + Layout.memberNumberGap)
    }

    private var afterMerging: some View {
        VStack(alignment: .leading, spacing: Space.s8) {
            Text("After merging")
                .font(RoomyFont.footnoteSemibold)
                .foregroundStyle(RoomyColor.textSecondary)
                .accessibilityAddTraits(.isHeader)
            mergedFields
        }
    }

    private var mergedFields: some View {
        VStack(alignment: .leading, spacing: Layout.mergePreviewSpacing) {
            if let organization = preview.organization {
                MergedFieldRow(label: "Company", value: organization)
            }
            // Keyed by position: a card can hold the same number twice under two labels, so values aren't unique.
            ForEach(Array(preview.phones.enumerated()), id: \.offset) {
                MergedFieldRow(label: "Phone", value: $0.element)
            }
            ForEach(Array(preview.emails.enumerated()), id: \.offset) {
                MergedFieldRow(label: "Email", value: $0.element)
            }
            if group.spansAccounts {
                note("These cards are in different accounts. The merged card stays in your own account.")
            }
            if preview.photosOnlyInBackup > 0 {
                note("The merged card keeps one photo. The other photos are saved only in the backup.")
            }
        }
        .padding(Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoomyColor.nested, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }

    private func note(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s8) {
            Image(systemName: "info.circle").accessibilityHidden(true)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(RoomyFont.footnote)
        .foregroundStyle(RoomyColor.textSecondary)
    }

    private var selectButton: some View {
        Button {
            Haptics.tap()
            onToggle()
        } label: {
            Label(
                isSelected ? "Merge selected" : "Merge \(group.members.count) cards",
                systemImage: isSelected ? "checkmark.circle.fill" : "arrow.triangle.merge"
            )
            .frame(maxWidth: .infinity, minHeight: Layout.tapTarget)
        }
        .buttonStyle(isSelected ? .roomyPrimary : .roomySecondary)
        .controlSize(.small)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Removes this merge from Review" : "Adds this merge to Review")
    }
}

extension ContactMatchReason {
    var label: String {
        switch self {
        case .samePhone: "Same number"
        case .sameEmail: "Same email"
        }
    }
}
