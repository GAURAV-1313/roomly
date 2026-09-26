// Why: every category screen offers one bulk action, and it now sits beside the Review capsule instead of in
// the nav bar, the hardest reach one-handed (Figma "Fix 5 · C"). It acts on exactly the items the screen shows,
// never on ones a filter or the library scope hides, and on Similar Photos only on the suggested extras, never
// on a keeper. It flips to "Deselect all" in place, so the target never moves under the thumb.
import Foundation

nonisolated struct BulkSelection {
    /// True when every item the action covers is already in the basket.
    let isAllSelected: Bool
    /// What VoiceOver names after "Select all", such as "extras"; nil reads just "Select all".
    var noun: String? = nil
    let toggle: @MainActor () -> Void

    var title: String { isAllSelected ? "Deselect all" : "Select all" }
    var systemImage: String { isAllSelected ? "checkmark.circle.fill" : "circle" }
    var accessibilityLabel: String {
        guard let noun else { return title }
        return "\(title) \(noun)"
    }
}
