// Why: a long-press preview shows a photo or screenshot as large as fits, in its own shape, so what is on it
// can be read before it is selected. The fitting is plain arithmetic, kept pure so it is tested.
import Foundation

nonisolated enum PreviewSize {
    /// The largest size with the asset's shape that fits `bounds`. Unknown dimensions take the bounds' shape.
    static func fitting(width: Int, height: Int, in bounds: CGSize) -> CGSize {
        guard width > 0, height > 0 else { return bounds }
        let scale = min(bounds.width / CGFloat(width), bounds.height / CGFloat(height))
        return CGSize(width: CGFloat(width) * scale, height: CGFloat(height) * scale)
    }
}
