// Why: a photo category may only say "all clear" when a scan that could see the whole library finished the
// work that category depends on. Deciding what the screen shows here, as a pure value, lets every one of
// those rules be unit-tested: no access, not scanned, still scanning, a stopped comparison, limited access.
import Foundation

nonisolated enum PhotoScanGateState: Equatable {
    /// A line shown above a category's content when its results are partial.
    enum Note: Equatable {
        /// Roomy sees only the photos the person picked.
        case limitedAccess
        /// The comparison was stopped; what shows comes from an earlier scan.
        case comparisonNotFinished
    }

    case askForAccess
    case denied
    case restricted
    case notScanned
    case scanning
    /// The comparison was stopped and nothing from an earlier scan is left to show.
    case comparisonNotFinished
    /// Nothing found. With limited access that covers only the photos the person picked.
    case empty(isLimited: Bool)
    case content(note: Note?)

    /// `needsComparison` is true for categories that only exist once photos are compared (similar photos).
    static func make(access: AccessState, phase: ScanPhase, isEmpty: Bool, needsComparison: Bool) -> Self {
        switch access {
        case .notDetermined: return .askForAccess
        case .denied: return .denied
        case .restricted: return .restricted
        case .limited, .authorized: break
        }
        let isLimited = access == .limited
        let isUnfinished = needsComparison && phase == .stopped
        switch (phase, isEmpty) {
        case (.idle, _): return .notScanned
        case (.indexing, true): return .scanning
        // Screenshots and videos are known once the library is read; only compared categories wait for comparing.
        case (.comparing, true) where needsComparison: return .scanning
        case (_, true) where isUnfinished: return .comparisonNotFinished
        case (_, true): return .empty(isLimited: isLimited)
        case (_, false) where isUnfinished: return .content(note: .comparisonNotFinished)
        case (_, false): return .content(note: isLimited ? .limitedAccess : nil)
        }
    }
}
