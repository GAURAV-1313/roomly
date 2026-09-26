// Why: Photos reports changes in bursts, including Roomy's own deletions, and during an iCloud sync or
// restore it never stops reporting them. A change made outside Roomy therefore never starts the full scan with its
// visible progress: that runs at launch and when the person asks. It only re-reads the index — quick, silent —
// so what is gone leaves every list and new screenshots and videos appear; new photos join similar groups at the
// next full scan. Automatic refreshes still keep a gap, so a syncing library isn't re-read without pause. These
// rules decide when a change earns a refresh and which kind. They are a plain value, so each rule is unit-tested
// without a photo library.
import Foundation

nonisolated struct LibraryRefreshPolicy: Equatable {
    enum Refresh: Equatable {
        case none
        /// Read the index again, quietly, without comparing.
        case reindex
    }

    /// Automatic refreshes start at least this long after the previous one ended, so a library that keeps
    /// changing is re-read now and then instead of without pause. Short, because a re-read is quick and silent.
    static let minimumGap: Duration = .seconds(30)

    /// The newest change already accounted for: a scan reads the library after it starts, and a cleanup's
    /// report updates every store with the changes it made.
    private(set) var coveredGeneration = 0
    /// When the last automatic refresh ended; nil until one has run.
    private(set) var lastAutomaticRefreshEnd: ContinuousClock.Instant?

    mutating func cover(through generation: Int) {
        coveredGeneration = max(coveredGeneration, generation)
    }

    mutating func automaticRefreshEnded(at instant: ContinuousClock.Instant) {
        lastAutomaticRefreshEnd = instant
    }

    /// A settled scan — finished, or a comparison the person stopped — has its index read again, so no list shows
    /// what is gone; the comparison itself waits for the next full scan. Before the first scan nothing is stale;
    /// during a cleanup the changes are Roomy's own, and its report updates every store.
    func refresh(after generation: Int, phase: ScanPhase, isCleaningUp: Bool, canUseLibrary: Bool) -> Refresh {
        guard canUseLibrary, !isCleaningUp, generation > coveredGeneration else { return .none }
        switch phase {
        case .done, .stopped: return .reindex
        case .idle, .indexing, .comparing: return .none
        }
    }

    /// How long the next automatic refresh must wait to keep the gap; zero when it may start now.
    func wait(before instant: ContinuousClock.Instant, gap: Duration = minimumGap) -> Duration {
        guard let lastAutomaticRefreshEnd else { return .zero }
        let remaining = gap - lastAutomaticRefreshEnd.duration(to: instant)
        return max(remaining, .zero)
    }
}
