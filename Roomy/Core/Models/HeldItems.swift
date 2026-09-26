// Why: between the confirmation and the cleanup the app keeps moving: access can change, a rescan can start, a
// contact group can vanish. Confirmed items that can't run safely at that moment are left alone, and these counts
// let the result say so, instead of skipping them without a word or calling them done.
import Foundation

/// Confirmed items a cleanup left alone because they couldn't run safely when it started. Nothing is done to
/// them; the result names each kind and why.
nonisolated struct HeldItems: Sendable, Equatable {
    /// Photos and videos, because Photos access is off.
    var waitingForPhotos = 0
    /// Similar photos, because the library is being compared again, so no one can check each group keeps one.
    var waitingForComparison = 0
    /// Contact merges whose group Roomy can't find right now.
    var waitingForContacts = 0
    /// Photos and videos kept only in iCloud, while Roomy shows only what is on this phone.
    var onlyInICloud = 0

    var isEmpty: Bool {
        waitingForPhotos == 0 && waitingForComparison == 0 && waitingForContacts == 0 && onlyInICloud == 0
    }
}
