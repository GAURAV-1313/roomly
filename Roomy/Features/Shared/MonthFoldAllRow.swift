// Why: with many months, folding or opening them one by one is a chore, so the list offers both at once above
// the months (Figma "Fix 4 · Collapsible months"). The words come from `MonthFolding`.
import SwiftUI

struct MonthFoldAllRow: View {
    let folding: MonthFolding
    let onFoldAll: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(folding.countLabel)
                .font(RoomyFont.subheadlineSemibold)
                .foregroundStyle(RoomyColor.textSecondary)
            Spacer()
            Button(folding.foldAllTitle, action: onFoldAll)
                .font(RoomyFont.subheadlineSemibold)
                .foregroundStyle(RoomyColor.accent)
                .frame(minHeight: Layout.tapTarget)
                .contentShape(Rectangle())
        }
    }
}
