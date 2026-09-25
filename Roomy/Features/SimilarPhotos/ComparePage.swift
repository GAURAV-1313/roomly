// Why: Compare shows whether the photo on screen is queued for removal apart from the button that changes it;
// one button titled "Keep this one" read like a status, so a queued photo looked safe. That holds for the
// keeper too: it can be queued (picked before it became the keeper, or while a comparison runs), and then it
// says so and can be taken out. The state, its words and actions are a pure value, so they are unit-tested.
import Foundation

nonisolated enum ComparePage: Equatable {
    case keeper
    /// The keeper, yet in the basket: it must say so and offer a way out.
    case keeperQueued
    case queued
    case notQueued

    init(isKeeper: Bool, isQueued: Bool) {
        switch (isKeeper, isQueued) {
        case (true, true): self = .keeperQueued
        case (true, false): self = .keeper
        case (false, true): self = .queued
        case (false, false): self = .notQueued
        }
    }

    var isKeeper: Bool { self == .keeper || self == .keeperQueued }
    var isQueued: Bool { self == .queued || self == .keeperQueued }

    /// What is true of this photo now, shown on the photo and read by VoiceOver.
    var status: String {
        switch self {
        case .keeper: "Keeper"
        case .keeperQueued: "Keeper · selected for removal"
        case .queued: "Selected for removal"
        case .notQueued: "Not selected"
        }
    }

    /// The button that flips the state. The keeper has none unless it is queued, when it can only be kept.
    var toggleTitle: String? {
        switch self {
        case .keeper: nil
        case .queued, .keeperQueued: "Keep this one"
        case .notQueued: "Remove this one"
        }
    }

    var toggleIcon: String {
        isQueued ? "arrow.uturn.backward" : "trash"
    }

    /// Any photo but the current keeper can be made the keeper.
    var canBecomeKeeper: Bool { !isKeeper }
}
