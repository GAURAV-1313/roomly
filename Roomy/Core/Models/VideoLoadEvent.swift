// Why: opening a video can mean an iCloud download, a failure, or a request that never answers. As a stream
// of events — progress, then the video or the reason there is none — the player screen always ends in
// something to show. Generic over the item, because Core cannot name AVFoundation's player item.
import Foundation

nonisolated enum VideoLoadEvent<Item: Sendable>: Sendable {
    /// Share of the iCloud download done, from 0 to 1.
    case downloading(Double)
    case ready(Item)
    case failed(VideoLoadFailure)
}
