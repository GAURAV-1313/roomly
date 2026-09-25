// Why: never compare every pair. Cheap certain links first (bursts, duplicates found through hash bands),
// then a short time window where a looser threshold is safe because the photos come from the same moment.
// Precision over recall: fewer, tighter groups beat one wrong merge. Flat photos, whose hashes say nothing,
// are never linked on their hash, and a group's label is one that holds for every member, never its best link.
import Foundation

nonisolated enum SimilarityEngine {
    /// A moment never spans more than this, from its first shot to its last.
    static let momentWindow: TimeInterval = 60
    /// Hamming distance that counts as a near-identical shot inside one moment.
    static let momentHammingLimit = 10
    /// Hamming distance that counts as a duplicate anywhere in the library. Every pair within it is found.
    static let duplicateHammingLimit = 4
    /// Hamming distance that counts as the same image saved again.
    static let exactHammingLimit = 2
    /// Each photo is compared with at most this many later photos, so a long shoot stays linear in cost.
    static let momentNeighbourLimit = 40

    static func group(_ snapshots: [AssetSnapshot], hashes: [String: HashRecord]) -> [SimilarGroup] {
        let photos = hashedPhotos(snapshots, hashes: hashes)
        guard photos.count > 1 else { return [] }
        var links = Links(count: photos.count)
        linkBursts(photos, into: &links)
        linkDuplicates(photos, into: &links)
        linkMoments(photos, into: &links)
        return makeGroups(photos, links: &links, hashes: hashes)
    }

    // MARK: - Steps

    private static func hashedPhotos(_ snapshots: [AssetSnapshot], hashes: [String: HashRecord]) -> [HashedPhoto] {
        snapshots
            .filter { $0.kind == .photo }
            .compactMap { snapshot in
                hashes[snapshot.id].map { HashedPhoto(snapshot: snapshot, hash: $0.dhash, hasDetail: $0.hasDetail) }
            }
            .sorted { ($0.snapshot.creationDate ?? .distantPast) < ($1.snapshot.creationDate ?? .distantPast) }
    }

    /// The camera says these frames belong together, so they are grouped whatever their hashes say.
    private static func linkBursts(_ photos: [HashedPhoto], into links: inout Links) {
        var bursts: [String: [Int]] = [:]
        for (index, photo) in photos.enumerated() {
            if let burst = photo.snapshot.burstIdentifier {
                bursts[burst, default: []].append(index)
            }
        }
        for members in bursts.values where members.count > 1 {
            for member in members.dropFirst() {
                links.link(members[0], member, reason: .burst)
            }
        }
    }

    private static func linkDuplicates(_ photos: [HashedPhoto], into links: inout Links) {
        let detailed = photos.indices.filter { photos[$0].hasDetail }
        NearHashIndex.forEachPair(in: detailed.map { photos[$0].hash }, within: duplicateHammingLimit) {
            first, second, distance in
            let reason: SimilarityReason = distance <= exactHammingLimit ? .exactDuplicate : .nearDuplicate
            links.link(detailed[first], detailed[second], reason: reason)
        }
    }

    /// A sliding window over photos in time order: each photo meets the ones after it until they are more than
    /// the window or the neighbour limit away, so a long run is covered in full and every pair is close in time.
    private static func linkMoments(_ photos: [HashedPhoto], into links: inout Links) {
        var moments = MomentClusters(dates: photos.map(\.snapshot.creationDate))
        for first in photos.indices where photos[first].hasDetail {
            var second = first + 1
            while second < photos.count, second - first <= momentNeighbourLimit,
                isWithinMoment(photos[first].snapshot, photos[second].snapshot)
            {
                if looksAlike(photos[first], photos[second]),
                    let span = moments.join(first, second, within: momentWindow)
                {
                    links.link(first, second, reason: .moment(seconds: span))
                }
                second += 1
            }
        }
    }

    private static func makeGroups(_ photos: [HashedPhoto], links: inout Links, hashes: [String: HashRecord])
        -> [SimilarGroup]
    {
        links.components().compactMap { component in
            let indices = component.members
            let members = indices.map { photos[$0].snapshot }
            guard let best = BestPicker.pick(members, hashes: hashes) else { return nil }
            let weakest = links.weakestReason(in: component)
            return SimilarGroup(
                id: StableID.make(from: members.map(\.id)),
                members: [best.id] + members.map(\.id).filter { $0 != best.id },
                best: best.id,
                reason: reason(weakest: weakest, members: members, hashes: indices.map { photos[$0].hash }),
                date: members.compactMap(\.creationDate).max(),
                links: component.pairs.map {
                    MemberLink(first: photos[$0.0].snapshot.id, second: photos[$0.1].snapshot.id)
                },
                markedByPerson: Set(members.filter(isMarkedByPerson).map(\.id)))
        }
        .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }
}

// MARK: - Helpers

nonisolated extension SimilarityEngine {
    static func aspectClass(_ snapshot: AssetSnapshot) -> Int {
        guard snapshot.pixelHeight > 0 else { return 0 }
        return Int((Double(snapshot.pixelWidth) / Double(snapshot.pixelHeight) * 4).rounded())
    }

    /// A label must hold for every pair of members, not only for the links that chained them: A~B and B~C
    /// within 2 bits can leave A and C 4 bits apart. So a duplicate label comes from the widest pair, and any
    /// other group's label is what holds for all members: one burst, one moment measured from its first shot
    /// to its last, or plainly similar. Removing members never makes such a label untrue.
    static func reason(weakest: SimilarityReason, members: [AssetSnapshot], hashes: [UInt64]) -> SimilarityReason {
        switch weakest {
        case .exactDuplicate, .nearDuplicate:
            let widest = widestDistance(hashes)
            if widest <= exactHammingLimit { return .exactDuplicate }
            if widest <= duplicateHammingLimit { return .nearDuplicate }
        case .burst, .moment, .similar: break
        }
        if let burst = members.first?.burstIdentifier, members.allSatisfy({ $0.burstIdentifier == burst }) {
            return .burst
        }
        let dates = members.compactMap(\.creationDate)
        guard dates.count == members.count, let first = dates.min(), let last = dates.max() else { return .similar }
        let span = last.timeIntervalSince(first)
        return span <= momentWindow ? .moment(seconds: Int(span.rounded())) : .similar
    }

    /// The largest Hamming distance between any two hashes. Groups are small, so every pair is checked.
    static func widestDistance(_ hashes: [UInt64]) -> Int {
        var widest = 0
        for first in hashes.indices {
            for second in hashes.indices where second > first {
                widest = max(widest, PerceptualHash.hamming(hashes[first], hashes[second]))
            }
        }
        return widest
    }

    /// A favourite, or a burst frame the person picked, in Photos.
    static func isMarkedByPerson(_ snapshot: AssetSnapshot) -> Bool {
        snapshot.isFavorite || snapshot.burstPick == .person
    }

    private static func isWithinMoment(_ first: AssetSnapshot, _ second: AssetSnapshot) -> Bool {
        guard let firstDate = first.creationDate, let secondDate = second.creationDate else { return false }
        return abs(secondDate.timeIntervalSince(firstDate)) <= momentWindow
    }

    private static func looksAlike(_ first: HashedPhoto, _ second: HashedPhoto) -> Bool {
        second.hasDetail
            && aspectClass(first.snapshot) == aspectClass(second.snapshot)
            && PerceptualHash.hamming(first.hash, second.hash) <= momentHammingLimit
    }
}

nonisolated struct HashedPhoto {
    let snapshot: AssetSnapshot
    let hash: UInt64
    /// False for flat frames, which are linked only as bursts, never on their hash.
    let hasDetail: Bool
}
