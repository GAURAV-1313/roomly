// Why: months arrive after the scan, so the default folding (the newest open, the rest folded once there are
// more than two) is applied the first time the screen has months, and only then: after that the person's own
// folding stands while the screen is on the stack, through Review, Compare or the player, and a later rescan
// that adds a month never snaps the list shut. The next visit starts from the default again.
import SwiftUI

private struct MonthFoldingDefault: ViewModifier {
    let ids: [String]
    @Binding var collapsed: Set<String>

    @State private var isSeeded = false

    func body(content: Content) -> some View {
        content.onChange(of: ids, initial: true) { _, ids in
            guard !isSeeded, !ids.isEmpty else { return }
            isSeeded = true
            collapsed = MonthSections.defaultCollapsed(ids)
        }
    }
}

extension View {
    /// Folds the older months the first time `ids` (newest first) is not empty.
    func foldingOlderMonths(_ ids: [String], into collapsed: Binding<Set<String>>) -> some View {
        modifier(MonthFoldingDefault(ids: ids, collapsed: collapsed))
    }
}
