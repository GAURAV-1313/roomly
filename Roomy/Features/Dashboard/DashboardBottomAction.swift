// Why: the dashboard has one action at the bottom, and which one it is follows the scan and the basket (Figma
// "Dashboard v5 — option A"). Before a scan it starts one; while it runs it cancels, filling with real progress;
// stopped, it resumes; done, it scans again. Once anything is saved Review takes the capsule, because Review
// is the only way to the one delete path, and the scan action, if one applies, becomes a round button beside
// it so neither hides the other. Without Photos access there is no scan action: the notice's Settings is it.
// Deciding this in a pure value keeps the view to layout and lets every rule be unit-tested.
import Foundation

nonisolated struct DashboardBottomAction: Equatable {
    /// What the scan control does, whether it is the capsule or the round button beside Review.
    enum Scan: Equatable {
        case start
        case cancel
        case resume
        case again

        var title: String {
            switch self {
            case .start: "Scan for space"
            case .cancel: "Cancel scan"
            case .resume: "Resume scan"
            case .again: "Scan again"
            }
        }

        var systemImage: String {
            switch self {
            case .start: "magnifyingglass"
            case .cancel: "xmark"
            case .resume: "play.fill"
            case .again: "arrow.clockwise"
            }
        }

        /// Starting and resuming are work waiting to be done, so they are navy; cancelling and rescanning stay quiet.
        var isProminent: Bool { self == .start || self == .resume }
    }

    /// The wide capsule: the scan action on its own, or Review.
    enum Capsule: Equatable {
        case scan(Scan)
        case review(title: String, isProminent: Bool)

        var title: String {
            switch self {
            case .scan(let scan): scan.title
            case .review(let title, _): title
            }
        }

        var systemImage: String {
            switch self {
            case .scan(let scan): scan.systemImage
            case .review: "checklist"
            }
        }

        var isProminent: Bool {
            switch self {
            case .scan(let scan): scan.isProminent
            case .review(_, let isProminent): isProminent
            }
        }

        /// What the capsule is for, apart from its words: the label crossfades only when this changes, and a
        /// count inside the same kind rolls instead.
        var kind: Kind {
            switch self {
            case .scan(let scan): .scan(scan)
            case .review: .review
            }
        }

        enum Kind: Hashable {
            case scan(Scan)
            case review
        }
    }

    /// Which pieces are on screen, and in which style; the morph animates when this changes, not on every count.
    struct Arrangement: Hashable {
        var capsule: Capsule.Kind?
        var isProminent: Bool
        var roundScan: Scan?
    }

    /// nil when there is nothing to do: no Photos access and nothing saved.
    let capsule: Capsule?
    /// The scan action as a round button beside Review; nil unless both apply.
    let roundScan: Scan?
    /// Real progress while a scan runs, from 0 to 1; nil before the library gives counts, so no bar starts at a
    /// made-up zero, and whenever nothing is scanning.
    let progress: Double?

    init(summary: DashboardSummary, reviewTitle: String?, isReviewReady: Bool) {
        let scan = Self.scan(for: summary)
        if let reviewTitle {
            capsule = .review(title: reviewTitle, isProminent: isReviewReady)
            roundScan = scan
        } else {
            capsule = scan.map(Capsule.scan)
            roundScan = nil
        }
        progress = scan == .cancel && summary.hasProgressCounts ? min(max(summary.progressFraction, 0), 1) : nil
    }

    var arrangement: Arrangement {
        Arrangement(capsule: capsule?.kind, isProminent: capsule?.isProminent ?? false, roundScan: roundScan)
    }

    /// What VoiceOver reads after "Cancel scan", such as "21%".
    var progressValue: String? {
        progress.map { $0.formatted(.percent.precision(.fractionLength(0))) }
    }

    private static func scan(for summary: DashboardSummary) -> Scan? {
        guard summary.canUseLibrary else { return nil }
        switch summary.phase {
        case .idle: return .start
        case .indexing, .comparing: return .cancel
        case .stopped: return .resume
        case .done: return .again
        }
    }
}
