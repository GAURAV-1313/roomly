// Why: while a cleanup runs, the sheet lists the steps the confirmed items need — contacts first, then photos —
// so the person sees what is done and what iOS is waiting on. A step is shown as done only if Roomy saw it run;
// a planned step that was skipped (nothing in it could run) disappears rather than earning a check it didn't.
import Foundation

nonisolated struct CleanupProgress: Equatable {
    enum State: Equatable {
        case done
        case active
        case upcoming
    }

    struct Row: Equatable, Identifiable {
        let step: CleanupStep
        let state: State

        var id: String { step.message }
    }

    /// The order the cleanup runs in: merges first, then Photos.
    static let order: [CleanupStep] = [.mergingContacts, .removingPhotos]

    let rows: [Row]

    /// - Parameters:
    ///   - planned: the steps the confirmed items need; the current step always shows, even if not planned.
    ///   - current: the step running now.
    ///   - seen: every step this view has seen running.
    init(planned: [CleanupStep], current: CleanupStep, seen: Set<CleanupStep>) {
        let steps = Self.order.filter { planned.contains($0) || $0 == current }
        let currentIndex = Self.order.firstIndex(of: current) ?? 0
        rows = steps.compactMap { step in
            let index = Self.order.firstIndex(of: step) ?? 0
            if step == current { return Row(step: step, state: .active) }
            if index > currentIndex { return Row(step: step, state: .upcoming) }
            return seen.contains(step) ? Row(step: step, state: .done) : nil
        }
    }

    /// The steps a set of confirmed items needs.
    static func planned(for summary: ReviewSummary) -> [CleanupStep] {
        order.filter { step in
            switch step {
            case .mergingContacts: summary.hasContacts
            case .removingPhotos: summary.hasAssets
            }
        }
    }
}

nonisolated extension CleanupStep {
    var message: String {
        switch self {
        case .mergingContacts: "Backing up and merging contacts…"
        case .removingPhotos: "Waiting for Photos. Confirm in the prompt to move the items to Recently Deleted."
        }
    }
}
