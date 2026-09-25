// Why: the store that follows library changes depends on this protocol, not on PHPhotoLibrary, so the rules
// for when a change earns a rescan can be driven by a fake in tests. The real one is `PhotoLibraryChanges`.
import Foundation

nonisolated protocol LibraryChangeSource: Sendable {
    /// Each element is the number of a change; only the newest waits while the consumer is busy.
    var changes: AsyncStream<Int> { get }
    /// The number of the newest change seen. A scan started now covers every change up to it.
    var generation: Int { get }
    /// Starts observing. Call only once Photos access is usable; later calls do nothing.
    func startObserving()
    /// Asks for any change made while the app was away and reports it on `changes`.
    @concurrent func checkForMissedChanges() async
}
