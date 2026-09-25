// Why: following library changes needs a library that can change during a test and that counts how often it
// was read, so a test can tell a rescan happened, happened once, or didn't happen at all.
import Foundation
import os

@testable import Roomy

final class ChangingPhotoSource: PhotoSource {
    private struct State {
        var library: FakePhotoSource
        var indexCount = 0
    }

    private let state: OSAllocatedUnfairLock<State>

    init(_ library: FakePhotoSource) {
        state = OSAllocatedUnfairLock(initialState: State(library: library))
    }

    /// How many times the library was read: once per scan or index refresh.
    var indexCount: Int { state.withLock { $0.indexCount } }

    func replaceSnapshots(_ snapshots: [AssetSnapshot]) {
        state.withLock { state in
            var library = FakePhotoSource(snapshots: snapshots, delay: state.library.delay)
            library.tileDelay = state.library.tileDelay
            state.library = library
        }
    }

    func indexLibrary() -> AsyncStream<IndexEvent> {
        state.withLock { state in
            state.indexCount += 1
            return state.library
        }
        .indexLibrary()
    }

    func fileSizes(for ids: [String]) async -> [String: AssetSize] {
        await state.withLock { $0.library }.fileSizes(for: ids)
    }

    func hashTiles(for id: String) async -> HashTiles? {
        await state.withLock { $0.library }.hashTiles(for: id)
    }
}
