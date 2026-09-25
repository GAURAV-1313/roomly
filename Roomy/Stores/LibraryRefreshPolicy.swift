// Why: Photos reports changes in bursts, including Roomy's own deletions, and during an iCloud sync or
// restore it never stops reporting them. Restarting on every change would never finish, and starting a fresh
// scan the moment the last one ends never finishes either, so automatic refreshes keep a gap. These rules
// decide when a change earns a refresh and which kind. They are a plain value, so each rule is unit-tested
// without a photo library.
import Foundation

nonisolated struct LibraryRefreshPolicy: Equatable {
    enum Refresh: Equatable {
        case none
        /// Index and compare again.
        case rescan
        /// Read the index again without comparing, because the person stopped the comparison.
        case reindex
    }

    /// Automatic refreshes start at least this long after the previous one ended, so a library that keeps
    /// changing is refreshed now and then instead of scanned without pause.
    static let minimumGap: Duration = .seconds(120)

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

    /// A finished scan refreshes itself. A comparison the person stopped stays stopped until they resume it,
    /// but its index is read again, so screenshots and videos don't list what is gone. Before the first scan
    /// nothing is stale; during a cleanup the changes are Roomy's own, and its report updates every store.
    func refresh(after generation: Int, phase: ScanPhase, isCleaningUp: Bool, canUseLibrary: Bool) -> Refresh {
        guard canUseLibrary, !isCleaningUp, generation > coveredGeneration else { return .none }
        switch phase {
        case .done: return .rescan
        case .stopped: return .reindex
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
