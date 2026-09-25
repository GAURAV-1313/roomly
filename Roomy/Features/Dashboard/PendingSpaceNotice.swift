// Why: the Recently Deleted reminder must say only what Roomy knows. Right after a cleanup the space is
// certainly waiting there; once free space has risen by more than the cleanups explain, Recently Deleted may
// have been emptied as part of that rise, so the reminder says the space may still be there instead of
// asserting it. The row has room for one short line; the full reason is read out as its hint.
import Foundation

nonisolated struct PendingSpaceNotice: Equatable {
    let title: String
    let message: String
    /// The longer explanation, for VoiceOver.
    let hint: String

    init(_ pending: PendingReclaim) {
        let bytes = pending.bytes.byteString
        if pending.isUncertain {
            title = "\(bytes) may be in Recently Deleted"
            message = "Roomy can't tell if it was emptied."
            hint =
                "Free space changed for other reasons too. If Recently Deleted wasn't emptied, "
                + "empty it in Photos to get the space back."
        } else {
            title = "\(bytes) in Recently Deleted"
            message = "Empty it in Photos to free it."
            hint = "It still uses space until Recently Deleted is emptied in Photos."
        }
    }
}
