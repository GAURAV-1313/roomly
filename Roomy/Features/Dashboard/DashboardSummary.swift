// Why: everything the dashboard shows is derived from scan state and free space. Computing it here, as a
// pure value, keeps the view to layout only and lets every label and mood rule be unit-tested. This file
// holds the storage card; the amount on its footer lives in DashboardSummary+Hero and the category tiles in
// DashboardSummary+Categories.
import Foundation

nonisolated struct DashboardSummary {
    /// Below this share of free space the robin looks concerned.
    static let lowSpaceThreshold = 0.10
    /// A scan that finds at least this much reclaimable space makes the robin pleased.
    static let pleasedThreshold: Int64 = 100_000_000
    /// Said wherever a stopped comparison would otherwise look like an empty result.
    static let comparisonNotFinished = "Comparison not finished"

    var phase: ScanPhase
    var volume: VolumeStats
    var canUseLibrary: Bool
    var indexProgress = IndexProgress()
    var hashProgress = HashProgress()
    var reclaimableBytes: Int64 = 0
    var similar = CategoryTotals()
    var screenshots = CategoryTotals()
    var videos = CategoryTotals()
    var contacts = ContactTotals()

    var isScanning: Bool { phase == .indexing || phase == .comparing }
    var isIndexed: Bool { phase == .comparing || phase == .stopped || phase == .done }

    var mood: MascotMood {
        if isScanning { return .thinking }
        if !canUseLibrary || volume.freeFraction < Self.lowSpaceThreshold { return .concerned }
        guard phase == .done else { return .idle }
        if reclaimableBytes >= Self.pleasedThreshold { return .pleased }
        return isAllTidy ? .resting : .idle
    }

    /// Nothing to clean up and every photo compared. Photos Roomy couldn't read (only in iCloud) were never
    /// checked, so the library isn't called tidy while any are left; nor is it while items were found whose
    /// space is only in iCloud or unknown, which count as zero bytes on this phone but are still there.
    private var isAllTidy: Bool {
        reclaimableBytes == 0 && foundCount == 0 && contacts.groups == 0 && similar.unchecked == 0
    }

    /// How full the phone is, for the usage bar. Reclaimable space is not drawn: it is far below one tick.
    var usedFraction: Double { StorageUsage(volume: volume).usedFraction }

    var cardTitle: String {
        if !canUseLibrary { return "Your storage" }
        switch phase {
        case .indexing, .comparing: return "Finding space"
        case .done where reclaimableBytes > 0 || foundCount > 0: return "Ready to clean up"
        case .done where similar.unchecked > 0: return "Nothing found so far"
        case .done: return "All tidy"
        case .stopped: return Self.comparisonNotFinished
        case .idle: return "Your storage"
        }
    }

    var usageTitle: String { StorageUsage(volume: volume).title }

    var usageDetail: String { StorageUsage(volume: volume).detail }

    var progressFraction: Double { phase == .comparing ? hashProgress.fraction : indexProgress.fraction }

    /// Real counts only: before the library says how many photos it holds, the card says what it is doing.
    var progressText: String {
        guard hasProgressCounts else { return phase == .comparing ? "Comparing photos" : "Reading your library" }
        if phase == .comparing {
            return "Comparing \(hashProgress.done.formatted()) of \(hashProgress.total.formatted()) photos"
        }
        return "\(indexProgress.scanned.formatted()) of \(indexProgress.total.formatted()) photos"
    }

    /// The progress bar shows only with real counts behind it; without them it would sit at a made-up zero.
    var hasProgressCounts: Bool { phase == .comparing ? hashProgress.total > 0 : indexProgress.total > 0 }

    /// The one action on the storage card follows the scan: stop it while it runs, run it again once done,
    /// and "Resume" when it was stopped, because the photos compared so far are kept. Before any scan the
    /// bottom button starts one instead.
    var cardAction: CardAction? {
        guard canUseLibrary else { return nil }
        switch phase {
        case .indexing, .comparing: return .cancel
        case .done: return .rescan
        case .stopped: return .resume
        case .idle: return nil
        }
    }

    enum CardAction: Equatable {
        case cancel
        case rescan
        case resume

        var title: String {
            switch self {
            case .cancel: "Cancel"
            case .rescan: "Rescan"
            case .resume: "Resume"
            }
        }
    }
}
