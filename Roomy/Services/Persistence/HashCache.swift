// Why: hashes are keyed by asset id and modification date, so a rescan only touches new or edited photos
// and finishes in seconds. An actor, because the scan reads and writes it from background tasks. A stopped
// scan can finish storing long after the Stop (a thumbnail request can't be interrupted), so every store
// carries the ticket its scan was given: only the newest scan replaces the cache, an older one only fills
// gaps, and nothing from before a clear is ever written back.
import Foundation

actor HashCache {
    /// Which scan a store comes from, and which clear it followed.
    nonisolated struct Ticket: Sendable, Equatable {
        fileprivate let scan: Int
        fileprivate let clearCount: Int
    }

    private let file: JSONFileStore<[String: HashRecord]>
    private var records: [String: HashRecord]?
    private var latestScan = 0
    private var clearCount = 0

    init(filename: String = "roomy-scan-cache.json") {
        file = JSONFileStore(filename: filename)
    }

    /// Called as a scan starts; the newest ticket is the only one whose store replaces the cache.
    func beginScan() -> Ticket {
        latestScan += 1
        return Ticket(scan: latestScan, clearCount: clearCount)
    }

    func load() -> [String: HashRecord] {
        if let records { return records }
        let loaded = file.load() ?? [:]
        records = loaded
        return loaded
    }

    /// The newest scan's records replace the cache, dropping photos that are gone. An older scan that ends
    /// late only adds records the cache lacks, so it never undoes newer work, and one from before a clear is
    /// ignored.
    func store(_ newRecords: [String: HashRecord], from ticket: Ticket) {
        guard ticket.clearCount == clearCount else { return }
        let next =
            ticket.scan == latestScan
            ? newRecords
            : load().merging(newRecords) { current, _ in current }
        records = next
        file.save(next)
    }

    func clear() {
        clearCount += 1
        records = [:]
        file.delete()
    }
}
