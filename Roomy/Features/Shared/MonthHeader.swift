// Why: both photo screens fold their months the same way, so the month row is built from a `MonthSummary` in
// one place: the summary line under the month, and the month's toggle only when it has something to select.
import SwiftUI

struct MonthHeader: View {
    let month: MonthSummary
    let isOpen: Bool
    let onToggleOpen: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        MonthDisclosureHeader(
            title: month.month, summary: month.summary, isOpen: isOpen, onToggleOpen: onToggleOpen,
            toggle: month.showsToggle ? toggle : nil)
    }

    private var toggle: SelectToggle {
        SelectToggle(
            title: month.toggleTitle, state: month.toggleState, accessibilityLabel: month.toggleAccessibilityLabel,
            accessibilityValue: month.toggleAccessibilityValue, action: onToggleSelection)
    }
}
