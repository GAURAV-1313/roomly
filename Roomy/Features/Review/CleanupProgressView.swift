// Why: the list the person approved becomes the progress in the same hero card family: Roomy thinking above the
// planned steps. While Photos asks for permission, the system prompt sits on top and this says what it is
// waiting for. The sheet has no Close while this runs.
import SwiftUI

struct CleanupProgressView: View {
    let step: CleanupStep
    /// The steps the confirmed items need, in the order they run.
    let planned: [CleanupStep]

    @State private var seen: Set<CleanupStep> = []

    var body: some View {
        let progress = CleanupProgress(planned: planned, current: step, seen: seen)
        ScrollView {
            VStack(spacing: -Layout.heroPerch) {
                MascotView(mood: .thinking, size: MascotSize.progress)
                    .zIndex(1)
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach(progress.rows) { CleanupStepRow(row: $0) }
                }
                .padding(.horizontal, Space.s16)
                .padding(.vertical, Space.s12)
                .heroInnerCard()
            }
            .padding(.top, Space.s16)
            .padding([.horizontal, .bottom], Layout.heroInset)
            .heroShell()
            .padding(.horizontal, Space.margin)
            .padding(.vertical, Space.s8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(RoomyColor.bg)
        .onChange(of: step, initial: true) { _, running in
            seen.insert(running)
        }
    }
}
