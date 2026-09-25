// Why: screens need pixels (thumbnails, video playback) but must never touch PhotoKit. These two entry
// points take an asset id and hand back ready-to-show values, and cancel their request when the screen stops
// listening.
import AVFoundation
import Photos
import UIKit

nonisolated extension PhotoLibrary {
    /// Photos answers for a video on this phone in well under a second and reports progress while it downloads
    /// one from iCloud, so this long with neither means the request is stuck.
    static let videoStallTimeout: Duration = .seconds(30)

    /// A fast degraded image first, then the final one. Cancelling the stream cancels the request.
    func thumbnails(id: String, pixelSize: CGSize) -> AsyncStream<UIImage> {
        AsyncStream { continuation in
            guard let asset = Self.asset(id) else {
                continuation.finish()
                return
            }
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
            let request = PHImageManager.default().requestImage(
                for: asset, targetSize: pixelSize, contentMode: .aspectFill, options: options
            ) { image, info in
                if let image {
                    continuation.yield(image)
                }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.finish()
                }
            }
            continuation.onTermination = { _ in PHImageManager.default().cancelImageRequest(request) }
        }
    }

    /// A video's player item, downloading it from iCloud if needed: progress while it downloads, then the item or
    /// the reason there is none. The stream always ends with `.ready` or `.failed`, and ending it early (the
    /// sheet closes) cancels the download.
    func video(_ id: String) -> AsyncStream<VideoLoadEvent<AVPlayerItem>> {
        Self.requestVideo(id).endingWhenStalled(after: Self.videoStallTimeout, with: .failed(.timedOut))
    }

    private static func requestVideo(_ id: String) -> AsyncStream<VideoLoadEvent<AVPlayerItem>> {
        AsyncStream { continuation in
            guard let asset = Self.asset(id) else {
                Log.media.error("video: asset not found \(id)")
                continuation.yield(.failed(.missing))
                continuation.finish()
                return
            }
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .automatic
            options.progressHandler = { progress, _, _, _ in
                continuation.yield(.downloading(progress))
            }
            let request = PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, info in
                continuation.yield(event(for: item, info: info, id: id))
                continuation.finish()
            }
            continuation.onTermination = { _ in PHImageManager.default().cancelImageRequest(request) }
        }
    }

    private static func event(for item: AVPlayerItem?, info: [AnyHashable: Any]?, id: String)
        -> VideoLoadEvent<AVPlayerItem>
    {
        if let item {
            return .ready(item)
        }
        if let error = info?[PHImageErrorKey] as? NSError {
            Log.media.error("video: \(id) unavailable: \(error.localizedDescription)")
        } else {
            Log.media.error("video: no item for \(id)")
        }
        return .failed(.unavailable)
    }
}
