// Why: with iCloud Photos and "Optimize iPhone Storage", Photos reports the full size of an original that is
// kept only in iCloud, and deleting it gives back almost nothing on this phone. So a size says where its bytes
// are, and only bytes on the phone count as space this phone can get back. This is the one rule that decides.
import Foundation

nonisolated struct AssetSize: Sendable, Hashable {
    /// One file behind an asset, as Photos describes it. Both facts come from undocumented keys, so either can
    /// be missing.
    struct File: Sendable, Equatable {
        var bytes: Int64?
        /// nil when Photos doesn't say where the file is.
        var isOnPhone: Bool?
    }

    /// Bytes of all the asset's files, wherever they are.
    let bytes: Int64
    /// The part of `bytes` kept only in iCloud: deleting frees it there, not on this phone.
    let inCloudOnly: Int64

    init(bytes: Int64, inCloudOnly: Int64 = 0) {
        self.bytes = bytes
        self.inCloudOnly = inCloudOnly
    }

    /// Bytes stored on this phone: what deleting the asset gives back here.
    var onPhone: Int64 { bytes - inCloudOnly }
    /// Some of its files are only in iCloud, so the size shown is not all space on this phone.
    var isInCloud: Bool { inCloudOnly > 0 }

    /// Adds up an asset's files. A file Photos says is not on the phone counts as in iCloud only; a file whose
    /// place Photos doesn't report counts as on the phone. nil when no file has a known size.
    static func measure(_ files: [File]) -> AssetSize? {
        var total: Int64?
        var inCloudOnly: Int64 = 0
        for file in files {
            guard let bytes = file.bytes else { continue }
            total = (total ?? 0) + bytes
            if file.isOnPhone == false {
                inCloudOnly += bytes
            }
        }
        return total.map { AssetSize(bytes: $0, inCloudOnly: inCloudOnly) }
    }
}
