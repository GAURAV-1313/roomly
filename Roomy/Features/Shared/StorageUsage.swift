// Why: how full the phone is reads the same wherever it appears — the dashboard card and the cleanup result — so
// the result feels like the next frame of the dashboard, and the words and the bar can never disagree.
import Foundation

nonisolated struct StorageUsage: Equatable {
    let volume: VolumeStats

    /// Share of the phone in use, for the usage bar.
    var usedFraction: Double { 1 - volume.freeFraction }

    /// "92% full".
    var title: String { "\(usedFraction.formatted(.percent.precision(.fractionLength(0)))) full" }

    /// "225 GB used · 20 GB free".
    var detail: String { "\(volume.used.byteString) used · \(volume.free.byteString) free" }
}
