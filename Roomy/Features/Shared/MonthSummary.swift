// Why: a folded month is one row, so that row must say what the month holds and how much of it is selected:
// "4 groups · 11 extras · 17 MB" with "7 of 11" beside it. The words are short so the summary stays on one line,
// never show a made-up size, and are derived here for both photo screens, as a pure value with tests.
import Foundation

nonisolated struct MonthSummary: Equatable {
    let month: String
    /// The line under the month's title.
    let summary: String
    /// What the month's toggle selects: suggested extras on Similar Photos, screenshots on Screenshots.
    let selectableCount: Int
    let selectedCount: Int
    /// What VoiceOver calls those items: "extras", "screenshots".
    let noun: String

    /// "4 groups · 11 extras · 17 MB"; the size is that of the suggested extras.
    static func similar(
        month: String, groupCount: Int, extraCount: Int, selectedCount: Int, size: SizeTotal
    ) -> MonthSummary {
        MonthSummary(
            month: month,
            summary: "\(groupCount.counted("group")) · \(extraCount.counted("extra")) · \(size.text)",
            selectableCount: extraCount, selectedCount: selectedCount, noun: "extras")
    }

    /// "24 · 36 MB".
    static func screenshots(month: String, count: Int, selectedCount: Int, size: SizeTotal) -> MonthSummary {
        MonthSummary(
            month: month, summary: "\(count.formatted()) · \(size.text)", selectableCount: count,
            selectedCount: selectedCount, noun: "screenshots")
    }

    /// A month whose every extra the person marked in Photos has nothing to select in bulk.
    var showsToggle: Bool { selectableCount > 0 }

    var toggleState: SelectionState { SelectionState(selected: selectedCount, of: selectableCount) }

    /// "Select 11", "11 selected" or "7 of 11".
    var toggleTitle: String {
        let total = selectableCount.formatted()
        switch toggleState {
        case .off: return "Select \(total)"
        case .mixed: return "\(selectedCount.formatted()) of \(total)"
        case .on: return "\(total) selected"
        }
    }

    /// "Select extras in August 2026".
    var toggleAccessibilityLabel: String { "Select \(noun) in \(month)" }

    /// "7 of 11 selected"; empty when none is.
    var toggleAccessibilityValue: String {
        toggleState == .off ? "" : "\(selectedCount.formatted()) of \(selectableCount.formatted()) selected"
    }
}
