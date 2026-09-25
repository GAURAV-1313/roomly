// Why: a stopped scan can store its hashes long after the Stop. These tests pin that such a late store never
// replaces a newer scan's hashes and never writes back a cache the person cleared in Settings.
import XCTest

@testable import Roomy

final class HashCacheTests: XCTestCase {
    private func makeCache() -> (cache: HashCache, filename: String) {
        let filename = "test-hashes-\(UUID().uuidString).json"
        addTeardownBlock { JSONFileStore<[String: HashRecord]>(filename: filename).delete() }
        return (HashCache(filename: filename), filename)
    }

    /// Regression: a stopped scan's late store overwrote the complete set a newer scan had just stored.
    func testALateStoreFromAnOlderScanOnlyFillsGaps() async {
        let (cache, filename) = makeCache()
        let stopped = await cache.beginScan()
        let newer = await cache.beginScan()
        await cache.store(["a": hashRecord(1), "b": hashRecord(2), "c": hashRecord(3)], from: newer)

        await cache.store(["a": hashRecord(9), "d": hashRecord(4)], from: stopped)
        let loaded = await cache.load()
        XCTAssertEqual(Set(loaded.keys), ["a", "b", "c", "d"], "the newer hashes stay; the gap is filled")
        XCTAssertEqual(loaded["a"]?.dhash, 1)
        let reloaded = await HashCache(filename: filename).load()
        XCTAssertEqual(reloaded, loaded)
    }

    func testTheNewestScanReplacesTheCache() async {
        let (cache, _) = makeCache()
        await cache.store(["gone": hashRecord(1)], from: await cache.beginScan())
        await cache.store(["kept": hashRecord(2)], from: await cache.beginScan())
        let keys = await cache.load().keys
        XCTAssertEqual(Set(keys), ["kept"], "photos no longer in the library leave the cache")
    }

    /// Regression: a scan stopped before "Clear cache" wrote its hashes back afterwards.
    func testAStoreFromBeforeAClearIsIgnored() async {
        let (cache, filename) = makeCache()
        let ticket = await cache.beginScan()
        await cache.clear()
        await cache.store(["a": hashRecord(1)], from: ticket)

        let loaded = await cache.load()
        XCTAssertTrue(loaded.isEmpty)
        let reloaded = await HashCache(filename: filename).load()
        XCTAssertTrue(reloaded.isEmpty)
    }
}
