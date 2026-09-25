// Why: a video row and the player sheet describe the same video in words — date, resolution, where its
// bytes are, its size — and never invent a value: no date reads "—", no size reads "size unavailable". The
// words are decided here, away from the views, so they are tested.
import Foundation

nonisolated struct VideoFact: Equatable, Identifiable {
    let title: String
    let value: String
    var id: String { title }
}

nonisolated enum VideoDetails {
    /// The row's second line: "12 Sep 2026 · 4K", with "· in iCloud" when the files aren't on this phone.
    static func rowLine(_ video: AssetSnapshot) -> String {
        let date = video.creationDate?.formatted(date: .abbreviated, time: .omitted)
        let place = video.size?.isInCloud == true ? SizeLabel.inCloud : nil
        let resolution = resolutionLabel(width: video.pixelWidth, height: video.pixelHeight)
        return [date, resolution, place].compactMap { $0 }.joined(separator: " · ")
    }

    /// "4K", "1080p", "720p", or the long side in pixels for anything smaller.
    static func resolutionLabel(width: Int, height: Int) -> String {
        let longSide = max(width, height)
        if longSide >= 3840 { return "4K" }
        if longSide >= 1920 { return "1080p" }
        if longSide >= 1280 { return "720p" }
        return "\(longSide)p"
    }

    /// The player sheet's facts, in order: when it was recorded, its pixels, and its size.
    static func facts(_ video: AssetSnapshot) -> [VideoFact] {
        [
            VideoFact(
                title: "Recorded", value: video.creationDate?.formatted(date: .long, time: .shortened) ?? "—"),
            VideoFact(title: "Resolution", value: "\(video.pixelWidth) × \(video.pixelHeight)"),
            VideoFact(title: "Size", value: SizeLabel.text(video.size)),
        ]
    }
}
