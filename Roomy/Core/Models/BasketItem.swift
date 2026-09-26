// Why: the basket stores only what the review screen needs — id, kind and size — so it can be saved to
// disk on every change and survive a crash. Contact merges sit in the same basket as photos, so there is
// one review and one confirmation for everything.
import Foundation

nonisolated struct BasketItem: Codable, Sendable, Hashable, Identifiable {
    /// Raw values match `AssetSnapshot.Kind`, so baskets saved before contacts existed still load.
    enum Kind: String, Codable, Sendable, CaseIterable {
        case photo
        case screenshot
        case video
        case contactGroup
    }

    let id: String
    let kind: Kind
    /// Bytes stored on this phone: what deleting the asset gives back here, and the only bytes Review adds up.
    /// nil for contact merges and for assets whose size is unavailable.
    let bytes: Int64?
    /// Bytes of originals kept only in iCloud, shown but never counted. nil when there are none, and in
    /// baskets saved before Roomy told the two apart.
    let bytesInCloud: Int64?

    init(id: String, kind: Kind, bytes: Int64?, bytesInCloud: Int64? = nil) {
        self.id = id
        self.kind = kind
        self.bytes = bytes
        self.bytesInCloud = bytesInCloud
    }

    init(_ snapshot: AssetSnapshot) {
        let inCloud = snapshot.size?.inCloudOnly ?? 0
        self.init(
            id: snapshot.id, kind: Kind(snapshot.kind), bytes: snapshot.bytesOnPhone,
            bytesInCloud: inCloud > 0 ? inCloud : nil)
    }

    init(_ group: ContactGroup) {
        self.init(id: group.id, kind: .contactGroup, bytes: nil)
    }

    /// Part of the asset was kept only in iCloud when Roomy last measured it.
    var isInCloud: Bool { (bytesInCloud ?? 0) > 0 }

    /// The same item with the size the scan measured last, so Review counts and holds it by where its files are
    /// now, not where they were when it was selected. Unchanged when the scan has no size for it.
    func refreshed(from snapshot: AssetSnapshot?) -> BasketItem {
        guard kind.isAsset, let snapshot, snapshot.id == id, snapshot.size != nil else { return self }
        return BasketItem(snapshot)
    }

    /// The size Review shows: the bytes on this phone plus any part kept only in iCloud.
    var size: AssetSize? {
        guard let bytes else { return nil }
        let inCloud = bytesInCloud ?? 0
        return AssetSize(bytes: bytes + inCloud, inCloudOnly: inCloud)
    }
}

nonisolated extension BasketItem.Kind {
    init(_ kind: AssetSnapshot.Kind) {
        switch kind {
        case .photo: self = .photo
        case .screenshot: self = .screenshot
        case .video: self = .video
        }
    }

    var isAsset: Bool { self != .contactGroup }
}
