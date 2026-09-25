// Why: the player sheet must always end in something to show — the video, download progress, or a plain
// reason it can't play with a way forward — never a spinner that turns forever. The states and their words
// are decided here, away from the view, so they are tested.
import Foundation

nonisolated enum VideoLoadState: Equatable {
    /// `progress` is the share of an iCloud download done, nil until Photos reports one.
    case loading(progress: Double?)
    case ready
    case failed(VideoLoadFailure)

    /// Moves to the state an event describes and hands back the video once it is ready.
    mutating func apply<Item>(_ event: VideoLoadEvent<Item>) -> Item? {
        switch event {
        case .downloading(let progress):
            self = .loading(progress: min(max(progress, 0), 1))
            return nil
        case .ready(let item):
            self = .ready
            return item
        case .failed(let failure):
            self = .failed(failure)
            return nil
        }
    }

    /// "Downloading from iCloud · 42%" while Photos reports progress; nil otherwise.
    var progressLabel: String? {
        guard case .loading(let progress?) = self else { return nil }
        return "Downloading from iCloud · \(progress.formatted(.percent.precision(.fractionLength(0))))"
    }

    var failureTitle: String? {
        guard case .failed(let failure) = self else { return nil }
        switch failure {
        case .missing: return "This video is gone"
        case .unavailable: return "Couldn't load this video"
        case .timedOut: return "This video is taking too long"
        }
    }

    var failureMessage: String? {
        guard case .failed(let failure) = self else { return nil }
        switch failure {
        case .missing: return "It's no longer in your library. It may have been deleted in Photos."
        case .unavailable: return "It may be kept in iCloud while this iPhone is offline. Check the connection."
        case .timedOut: return "Photos didn't answer. It may be downloading from iCloud on a slow connection."
        }
    }

    /// A video that is no longer in the library can't come back, so only the other failures offer Retry.
    var canRetry: Bool {
        guard case .failed(let failure) = self else { return false }
        return failure != .missing
    }
}
