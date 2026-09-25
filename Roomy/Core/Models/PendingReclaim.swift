// Why: deleting a photo moves it to Recently Deleted, where it still uses space for 30 days. Roomy remembers
// how much each cleanup moved and how much was free before, and reports a rise only after free space is
// measured again — never more than it moved, and only when the rise is about the size of what it moved. A
// much bigger rise has another cause Roomy didn't see (an app deleted, a cache cleared), so it keeps the
// reminder and measures from there instead — but that rise may include Recently Deleted being emptied, so from
// then on the space is only possibly waiting, and nothing may claim it still is. Each cleanup keeps its own
// 30 days.
import Foundation

nonisolated struct PendingReclaim: Codable, Sendable, Equatable {
    /// Free space moves on its own (caches, downloads, updates), so a rise counts as the cleanup's only once
    /// it reaches this share of what was moved.
    static let confirmationShare = 0.5
    /// A rise beyond this multiple of what was moved is more than the cleanups can explain, so it proves
    /// nothing about Recently Deleted.
    static let explainedRiseFactor = 1.5
    /// iOS empties Recently Deleted on its own after this long.
    static let retention: TimeInterval = 30 * 24 * 60 * 60

    /// What one cleanup moved to Recently Deleted.
    nonisolated struct Entry: Codable, Sendable, Equatable {
        let bytes: Int64
        let itemCount: Int
        let date: Date

        func hasExpired(at now: Date) -> Bool {
            now.timeIntervalSince(date) > PendingReclaim.retention
        }
    }

    /// What a fresh free-space reading says about the space still waiting.
    enum Reading: Equatable {
        /// Free space hasn't risen enough to be the cleanups' space.
        case waiting
        /// Free space rose by about what was moved; the amount credited is capped at what was moved.
        case reclaimed(Int64)
        /// Free space rose by far more than was moved: something else freed space, so Roomy can't tell
        /// whether Recently Deleted was emptied.
        case unexplained
    }

    /// One entry per cleanup, oldest first.
    private(set) var entries: [Entry]
    /// Free space just before the newest cleanup, raised by whatever has expired since.
    private(set) var freeBefore: Int64
    /// True once free space rose by more than the cleanups explain: Recently Deleted may have been emptied as
    /// part of that rise, so Roomy no longer knows the space is still waiting.
    private(set) var isUncertain: Bool

    init(entries: [Entry], freeBefore: Int64, isUncertain: Bool = false) {
        self.entries = entries
        self.freeBefore = freeBefore
        self.isUncertain = isUncertain
    }

    var bytes: Int64 { entries.reduce(0) { $0 + $1.bytes } }
    var itemCount: Int { entries.reduce(0) { $0 + $1.itemCount } }

    func reading(freeNow: Int64) -> Reading {
        let moved = Double(bytes)
        let rise = freeNow - freeBefore
        guard moved > 0, rise > 0, Double(rise) >= moved * Self.confirmationShare else { return .waiting }
        guard Double(rise) <= moved * Self.explainedRiseFactor else { return .unexplained }
        return .reclaimed(min(rise, bytes))
    }

    /// The same cleanups measured from `freeNow`, after a rise Roomy can't explain, so a later emptying of
    /// Recently Deleted is measured from here. The rise may itself have been that emptying, so they are marked
    /// uncertain.
    func rebased(freeNow: Int64) -> PendingReclaim {
        PendingReclaim(entries: entries, freeBefore: freeNow, isUncertain: true)
    }

    /// Drops cleanups iOS has emptied on its own. Their space came back without the person, so the baseline
    /// rises by it and it is never credited to the cleanups still waiting. Nil when nothing is left.
    func expiring(at now: Date) -> PendingReclaim? {
        let active = entries.filter { !$0.hasExpired(at: now) }
        guard !active.isEmpty else { return nil }
        let expiredBytes = bytes - active.reduce(0) { $0 + $1.bytes }
        return PendingReclaim(entries: active, freeBefore: freeBefore + expiredBytes, isUncertain: isUncertain)
    }

    /// Adds a cleanup. Its fresh free-space reading becomes the baseline: every cleanup still waiting was
    /// on disk at that moment.
    func adding(_ entry: Entry, freeBefore newBaseline: Int64) -> PendingReclaim {
        let active = entries.filter { !$0.hasExpired(at: entry.date) }
        // Older cleanups stay uncertain: the new baseline says nothing about whether they are still there.
        return PendingReclaim(entries: active + [entry], freeBefore: newBaseline, isUncertain: isUncertain)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case entries
        case freeBefore
        case isUncertain
        // A file saved before cleanups were kept one by one holds a single cleanup in these keys.
        case bytes
        case itemCount
        case date
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        freeBefore = try container.decode(Int64.self, forKey: .freeBefore)
        // Files saved before this was recorded had never seen an unexplained rise.
        isUncertain = try container.decodeIfPresent(Bool.self, forKey: .isUncertain) ?? false
        if let entries = try container.decodeIfPresent([Entry].self, forKey: .entries) {
            self.entries = entries
        } else {
            entries = [
                Entry(
                    bytes: try container.decode(Int64.self, forKey: .bytes),
                    itemCount: try container.decode(Int.self, forKey: .itemCount),
                    date: try container.decode(Date.self, forKey: .date))
            ]
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entries, forKey: .entries)
        try container.encode(freeBefore, forKey: .freeBefore)
        try container.encode(isUncertain, forKey: .isUncertain)
    }
}
