// Why: turning a PHAsset into a snapshot involves two judgement calls — which assets count as screenshots
// and how to size them — so they live in one small, documented place.
import Photos

nonisolated enum AssetMetadata {
    static func snapshot(from asset: PHAsset) -> AssetSnapshot {
        let kind = kind(of: asset)
        return AssetSnapshot(
            id: asset.localIdentifier,
            kind: kind,
            creationDate: asset.creationDate,
            modificationDate: asset.modificationDate,
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            duration: asset.duration,
            burstIdentifier: asset.burstIdentifier,
            isFavorite: asset.isFavorite,
            filename: kind == .video ? originalFilename(of: asset) : nil,
            // Sizes are read eagerly only where the list shows them; photos are sized later, if grouped.
            size: kind == .photo ? nil : size(of: asset),
            burstPick: burstPick(of: asset))
    }

    /// The frame the person or the camera chose from a burst is the natural keeper of its group.
    static func burstPick(of asset: PHAsset) -> AssetSnapshot.BurstPick {
        guard asset.burstIdentifier != nil else { return .none }
        if asset.burstSelectionTypes.contains(.userPick) { return .person }
        if asset.burstSelectionTypes.contains(.autoPick) { return .camera }
        return .none
    }

    static func kind(of asset: PHAsset) -> AssetSnapshot.Kind {
        if asset.mediaType == .video { return .video }
        if asset.mediaSubtypes.contains(.photoScreenshot) { return .screenshot }
        #if targetEnvironment(simulator)
            // The simulator cannot create the screenshot subtype, so phone-shaped PNGs stand in for one. The
            // resource lookup is slow, so it runs only for portrait images.
            guard asset.pixelHeight > asset.pixelWidth else { return .photo }
            let isPNG = PHAssetResource.assetResources(for: asset).first?.uniformTypeIdentifier == "public.png"
            if isPNG { return .screenshot }
        #endif
        return .photo
    }

    /// Every resource's size and whether it is on this phone (edited and Live Photos have several files). There
    /// is no public API for either: the `fileSize` and `locallyAvailable` keys are what shipping cleaners read,
    /// and Apple may change them, so both are optional and `AssetSize.measure` decides what counts.
    static func size(of asset: PHAsset) -> AssetSize? {
        let files = PHAssetResource.assetResources(for: asset).map { resource in
            AssetSize.File(bytes: bytes(of: resource), isOnPhone: isOnPhone(resource))
        }
        return AssetSize.measure(files)
    }

    static func originalFilename(of asset: PHAsset) -> String? {
        PHAssetResource.assetResources(for: asset).first?.originalFilename
    }

    /// Asking for a key an object doesn't have raises an Objective-C exception Swift can't catch, and a new iOS
    /// may rename this undocumented one. KVC finds a key through a getter or a backing ivar, so both are checked:
    /// only if neither exists does the size read as unavailable instead of crashing the scan.
    private static func bytes(of resource: PHAssetResource) -> Int64? {
        guard hasFileSizeKey else { return nil }
        let value = resource.value(forKey: "fileSize")
        if let bytes = value as? Int64 { return bytes }
        if let bytes = value as? Int { return Int64(bytes) }
        return nil
    }

    /// Checked once: the class, not each resource, decides whether the key exists.
    private static let hasFileSizeKey: Bool = {
        let type: AnyClass = PHAssetResource.self
        let getter = class_getInstanceMethod(type, NSSelectorFromString("fileSize")) != nil
        let ivarNames: [String] = ["_fileSize", "fileSize"]
        let ivar = ivarNames.contains { class_getInstanceVariable(type, $0) != nil }
        return getter || ivar
    }()

    /// False for an original that "Optimize iPhone Storage" keeps only in iCloud; nil when Photos doesn't say.
    /// Asking for a key an object doesn't have raises an Objective-C exception, which Swift can't catch, so the
    /// getter is checked first: if Apple removes the key, availability reads as unknown instead of crashing.
    private static func isOnPhone(_ resource: PHAssetResource) -> Bool? {
        let getters = ["isLocallyAvailable", "locallyAvailable"]
        guard getters.contains(where: { resource.responds(to: NSSelectorFromString($0)) }) else { return nil }
        return resource.value(forKey: "locallyAvailable") as? Bool
    }
}
