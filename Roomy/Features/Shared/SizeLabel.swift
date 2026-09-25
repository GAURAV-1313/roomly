// Why: a size reads the same on every screen and is never made up: the number when Photos gave one, "size
// unavailable" when it didn't, and "in iCloud" beside it when the files aren't on this phone, so a big number
// is never mistaken for space this phone can get back.
import Foundation

nonisolated enum SizeLabel {
    static let unavailable = "size unavailable"
    static let inCloud = "in iCloud"

    /// "1.2 GB", "3 GB · in iCloud" or "size unavailable".
    static func text(_ size: AssetSize?) -> String {
        guard let size else { return unavailable }
        guard size.isInCloud else { return size.bytes.byteString }
        return "\(size.bytes.byteString) · \(inCloud)"
    }

    /// The number alone, for rows that say "in iCloud" on another line.
    static func value(_ size: AssetSize?) -> String {
        size?.bytes.byteString ?? unavailable
    }
}
