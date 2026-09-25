// Why: "couldn't load" has different causes and different ways forward — a deleted video can't come back, an
// offline download can be tried again — so the reason travels as data from the service to the screen.
import Foundation

nonisolated enum VideoLoadFailure: Sendable, Equatable {
    /// The video is no longer in the library, for example deleted in Photos since the scan.
    case missing
    /// Photos couldn't hand it over, for example a video kept in iCloud while this phone is offline.
    case unavailable
    /// Photos neither answered nor reported download progress for too long.
    case timedOut
}
