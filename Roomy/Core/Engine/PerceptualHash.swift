// Why: a difference hash is 64 bits from a 9×8 grayscale tile — microseconds per photo — and catches
// duplicates, re-saves and light edits. Sharpness ranks photos inside a group; contrast tells a real picture
// from a flat frame whose hash says nothing. All are pure functions, so they are fully unit-tested and
// identical on every device.
import CoreGraphics
import Foundation

nonisolated enum PerceptualHash {
    /// `gray` is 9 columns × 8 rows, row-major, 0–255. Bit is 1 where a pixel is brighter than its right neighbour.
    static func dhash(gray9x8 gray: [UInt8]) -> UInt64 {
        precondition(gray.count == 72, "dhash needs a 9×8 tile")
        var bits: UInt64 = 0
        for row in 0..<8 {
            for column in 0..<8 {
                let left = gray[row * 9 + column]
                let right = gray[row * 9 + column + 1]
                bits = (bits << 1) | (left > right ? 1 : 0)
            }
        }
        return bits
    }

    static func hamming(_ first: UInt64, _ second: UInt64) -> Int {
        (first ^ second).nonzeroBitCount
    }

    /// Standard deviation of a tile's brightness, 0–127.5. Near zero for black pocket shots, blown-out white
    /// and blank walls, whose hashes carry no information about what is in the picture.
    static func contrast(gray: [UInt8]) -> Double {
        guard !gray.isEmpty else { return 0 }
        let values = gray.map(Double.init)
        let mean = values.reduce(0, +) / Double(values.count)
        return (values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)).squareRoot()
    }

    /// Variance of a 3×3 Laplacian. Higher is sharper. Used to rank inside a group, never as a verdict:
    /// portraits and night shots score low on purpose.
    static func laplacianVariance(gray: [UInt8], width: Int, height: Int) -> Double {
        guard width >= 3, height >= 3, gray.count == width * height else { return 0 }
        var responses: [Double] = []
        responses.reserveCapacity((width - 2) * (height - 2))
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let center = Double(gray[y * width + x])
                let above = Double(gray[(y - 1) * width + x])
                let below = Double(gray[(y + 1) * width + x])
                let left = Double(gray[y * width + x - 1])
                let right = Double(gray[y * width + x + 1])
                responses.append(above + below + left + right - 4 * center)
            }
        }
        let mean = responses.reduce(0, +) / Double(responses.count)
        return responses.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(responses.count)
    }

    /// Deterministic downscale to an exact grayscale size. Photos returns whatever tile it has cached,
    /// so we resample ourselves; otherwise hashes differ between devices and the cache is worthless.
    static func grayscale(_ image: CGImage, width: Int, height: Int) -> [UInt8]? {
        var pixels = [UInt8](repeating: 0, count: width * height)
        let didDraw = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard
                let context = CGContext(
                    data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                    bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGImageAlphaInfo.none.rawValue)
            else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return didDraw ? pixels : nil
    }
}
