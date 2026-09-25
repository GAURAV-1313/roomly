// Why: no API returns exactly the number in Settings › iPhone Storage. "Important usage" capacity is the
// closest to what people call available. We show it, never claim it matches to the byte, and (privacy
// manifest reason 85F4.1) it never leaves the device.
import Foundation

nonisolated struct VolumeStats: Sendable, Equatable {
    let total: Int64
    let free: Int64

    var used: Int64 { max(total - free, 0) }
    var freeFraction: Double { total == 0 ? 1 : Double(free) / Double(total) }

    static func current() -> VolumeStats {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        let values = try? URL.homeDirectory.resourceValues(forKeys: keys)  // unavailable reads as 0, never crashes
        return VolumeStats(
            total: Int64(values?.volumeTotalCapacity ?? 0),
            free: values?.volumeAvailableCapacityForImportantUsage ?? 0)
    }
}
