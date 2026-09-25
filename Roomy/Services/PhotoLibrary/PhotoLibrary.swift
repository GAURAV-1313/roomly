// Why: the one owner of PhotoKit for the scan. It enumerates the library once, in a detached task so the
// UI never waits, and hands out only Sendable snapshots and tiles.
import Photos

nonisolated struct PhotoLibrary: PhotoSource {
    /// Progress is reported every this many assets: frequent enough to feel live, rare enough to be cheap.
    static let progressInterval = 200
    /// A thumbnail that hasn't arrived by then is skipped, so one stuck request never stalls the scan.
    static let tileTimeout: Duration = .seconds(20)

    func indexLibrary() -> AsyncStream<IndexEvent> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                let snapshots = Self.enumerateLibrary { continuation.yield(.progress($0)) }
                if !Task.isCancelled {
                    continuation.yield(.finished(snapshots))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func fileSizes(for ids: [String]) async -> [String: AssetSize] {
        guard !ids.isEmpty else { return [:] }
        var sizes: [String: AssetSize] = [:]
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: .matchingIndex())
        if assets.count < ids.count {
            // The burst check in docs/PERFORMANCE.md reads this: unpicked frames missing here would mean fetching
            // by id ignores includeAllBurstAssets. Photos deleted since the index also land here.
            Log.scan.notice("sizes: \(ids.count - assets.count) of \(ids.count) ids not found")
        }
        assets.enumerateObjects { asset, _, _ in
            if let size = AssetMetadata.size(of: asset) {
                sizes[asset.localIdentifier] = size
            }
        }
        return sizes
    }

    func hashTiles(for id: String) async -> HashTiles? {
        guard let asset = Self.asset(id) else {
            Log.scan.error("hash: asset not found \(id)")
            return nil
        }
        // The fast path uses Photos' cached tile. Fresh imports (and the simulator) may not have one and
        // answer error 3303, so fall back to a single high-quality decode.
        if let tiles = await Self.requestTiles(asset, mode: .fastFormat) {
            return tiles
        }
        return await Self.requestTiles(asset, mode: .highQualityFormat)
    }

    static func asset(_ id: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [id], options: .matchingIndex()).firstObject
    }

    // MARK: - Private

    private static func enumerateLibrary(onProgress: @escaping (IndexProgress) -> Void) -> [AssetSnapshot] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false
        // Every burst frame, not only the one Photos shows: the others are the most common near-identical shots.
        options.includeAllBurstAssets = true
        options.includeAssetSourceTypes = [.typeUserLibrary]
        options.wantsIncrementalChangeDetails = false

        let result = PHAsset.fetchAssets(with: options)
        var snapshots: [AssetSnapshot] = []
        snapshots.reserveCapacity(result.count)
        var progress = IndexProgress(total: result.count)
        // Sequential enumeration: random access thrashes PHFetchResult's internal window.
        result.enumerateObjects { asset, _, stop in
            let snapshot = AssetMetadata.snapshot(from: asset)
            snapshots.append(snapshot)
            progress.record(snapshot.kind)
            if progress.scanned.isMultiple(of: progressInterval) || progress.scanned == progress.total {
                onProgress(progress)
            }
            if Task.isCancelled {
                stop.pointee = true
            }
        }
        return snapshots
    }

    /// The handler is documented as "called one or more times", so the continuation resumes through
    /// `ResumeOnce` even though the delivery modes used here normally answer once.
    private static func requestTiles(_ asset: PHAsset, mode: PHImageRequestOptionsDeliveryMode) async -> HashTiles? {
        await withCheckedContinuation { continuation in
            let once = ResumeOnce(continuation)
            let timeout = Task {
                // try? is deliberate: the sleep throws only when the image arrived and cancelled it.
                try? await Task.sleep(for: tileTimeout)
                if !Task.isCancelled {
                    once.resume(returning: nil)
                }
            }
            let options = PHImageRequestOptions()
            options.deliveryMode = mode
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
            let size = CGSize(width: 96, height: 96)
            PHImageManager.default().requestImage(
                for: asset, targetSize: size, contentMode: .aspectFill, options: options
            ) { image, _ in
                timeout.cancel()
                guard
                    let cgImage = image?.cgImage,
                    let gray9x8 = PerceptualHash.grayscale(cgImage, width: 9, height: 8),
                    let gray32 = PerceptualHash.grayscale(cgImage, width: 32, height: 32)
                else {
                    once.resume(returning: nil)
                    return
                }
                once.resume(returning: HashTiles(gray9x8: gray9x8, gray32: gray32))
            }
        }
    }
}

nonisolated extension IndexProgress {
    mutating func record(_ kind: AssetSnapshot.Kind) {
        scanned += 1
        switch kind {
        case .screenshot: screenshots += 1
        case .video: videos += 1
        case .photo: break
        }
    }
}
