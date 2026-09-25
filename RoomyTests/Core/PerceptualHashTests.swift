// Why: the hash and sharpness functions decide what gets grouped and which photo is kept; their exact
// behaviour is pinned here.
import CoreGraphics
import XCTest

@testable import Roomy

final class PerceptualHashTests: XCTestCase {
    func testHashIsDeterministicAndSensitive() {
        let base = (0..<72).map { UInt8($0 * 3) }
        let hash = PerceptualHash.dhash(gray9x8: base)
        XCTAssertEqual(hash, PerceptualHash.dhash(gray9x8: base))
        var changed = base
        changed[0] = 255
        changed[1] = 0
        XCTAssertGreaterThan(PerceptualHash.hamming(hash, PerceptualHash.dhash(gray9x8: changed)), 0)
        XCTAssertEqual(PerceptualHash.hamming(0, .max), 64)
    }

    func testLaplacianVarianceRanksSharpness() {
        let flat = [UInt8](repeating: 128, count: 32 * 32)
        let checkerboard = (0..<(32 * 32)).map { index -> UInt8 in
            let x = index % 32
            let y = index / 32
            return (x / 4 + y / 4).isMultiple(of: 2) ? 0 : 255
        }
        XCTAssertEqual(PerceptualHash.laplacianVariance(gray: flat, width: 32, height: 32), 0)
        XCTAssertGreaterThan(PerceptualHash.laplacianVariance(gray: checkerboard, width: 32, height: 32), 1000)
    }

    /// A smooth gradient hashes to all zeros: why a test library made only of gradients groups everything.
    func testGrayscaleDownscaleOfAGradient() throws {
        let width = 120
        let height = 90
        var rgba = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let value = UInt8(x * 255 / (width - 1))
                let offset = (y * width + x) * 4
                rgba[offset] = value
                rgba[offset + 1] = value
                rgba[offset + 2] = value
            }
        }
        let image = try XCTUnwrap(makeImage(rgba, width: width, height: height))
        let gray = try XCTUnwrap(PerceptualHash.grayscale(image, width: 9, height: 8))
        XCTAssertLessThan(gray[0], gray[8], "left column must be darker than the right")
        XCTAssertEqual(PerceptualHash.dhash(gray9x8: gray), 0)
    }

    private func makeImage(_ rgba: [UInt8], width: Int, height: Int) -> CGImage? {
        var pixels = rgba
        return pixels.withUnsafeMutableBytes { buffer in
            CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )?.makeImage()
        }
    }
}
