// Why: a merge is approved by reading its result, so each group shows the card it will become — every phone
// and email, with values from the other cards tagged, and whether it moves data between accounts — before
// anything is selected. Selected groups get the accent ring and a prominent button, like selected videos.
import SwiftUI

struct ContactGroupCard: View {
    let group: ContactGroup
    let preview: MergePreview
    let isSelected: Bool
    let onToggle: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            header
            mergedFields
            selectButton
        }
        .padding(Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
        .selectedRing(isSelected)
    }

    /// At accessibility sizes the reason tag moves under the name instead of squeezing it.
    private var header: some View {
        let isStacked = dynamicTypeSize.isAccessibilitySize
        return HStack(alignment: isStacked ? .top : .center, spacing: Space.s12) {
            avatar
            VStack(alignment: .leading, spacing: Space.s2) {
                Text(preview.name.isEmpty ? "No name" : preview.name)
                    .font(RoomyFont.headline)
                    .foregroundStyle(RoomyColor.textPrimary)
                Text("\(group.members.count) cards")
                    .font(RoomyFont.footnote)
                    .foregroundStyle(RoomyColor.textSecondary)
                if isStacked {
                    ReasonChip(text: group.reason.label, tint: Route.duplicateContacts.categoryTintSoft).padding(
                        .top, Space.s4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            if !isStacked {
                ReasonChip(text: group.reason.label, tint: Route.duplicateContacts.categoryTintSoft)
            }
        }
        .padding([.leading, .top], Space.s4)
    }

    private var avatar: some View {
        Text(initials)
            .font(RoomyFont.headline)
            .foregroundStyle(Route.duplicateContacts.categoryTint)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .frame(width: Layout.tapTarget, height: Layout.tapTarget)
            .background(Route.duplicateContacts.categoryTintSoft, in: Circle())
            .accessibilityHidden(true)
    }

    private var mergedFields: some View {
        VStack(alignment: .leading, spacing: Layout.mergePreviewSpacing) {
            if !preview.organization.isEmpty {
                MergedFieldRow(label: "Company", value: MergedValue(text: preview.organization, isAdded: false))
            }
            ForEach(preview.phones, id: \.self) { MergedFieldRow(label: "Phone", value: $0) }
            ForEach(preview.emails, id: \.self) { MergedFieldRow(label: "Email", value: $0) }
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

    private var initials: String {
        let words = preview.name.split(separator: " ").prefix(2)
        let letters = words.compactMap(\.first).map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
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
