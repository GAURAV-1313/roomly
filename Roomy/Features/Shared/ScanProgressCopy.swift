// Why: the progress card on a category that waits for the comparison must show real counts only. Before the
// comparison has a total there is no count to show, so the card says what is happening and nothing more, and its
// bar stays hidden rather than sitting at a made-up zero. Pure, so those rules are unit-tested.
import Foundation

nonisolated struct ScanProgressCopy: Equatable {
    let phase: ScanPhase
    let hashProgress: HashProgress

    /// Leaving is always fine: the scan keeps running and the screen fills in when the person comes back.
    static let leaveNote = "You can leave this screen."

    /// Counts exist only once the comparison knows how many photos it will look at.
    var hasCounts: Bool { phase == .comparing && hashProgress.total > 0 }

    var title: String { phase == .comparing ? "Comparing photos" : "Reading your library" }

    var message: String {
        guard hasCounts else { return Self.leaveNote }
        return "\(counts) · \(Self.leaveNote)"
    }

    /// The bar's fill, or nil while there is nothing real to fill it with.
    var fraction: Double? { hasCounts ? hashProgress.fraction : nil }

    /// One VoiceOver element: the title and, once they exist, the counts.
    var accessibilityLabel: String { hasCounts ? "\(title), \(counts)" : title }

    private var counts: String { "\(hashProgress.done.formatted()) of \(hashProgress.total.formatted())" }
}
