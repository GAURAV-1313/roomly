// Why: Review, the cleanup and its result are one sheet with three states, so the person never loses their
// place: the list they approved becomes the progress, then the honest result. The sheet can't be swiped
// away only while a cleanup is running; every other state has a Close button. The selected detent chooses
// the total card's size, and the steps the progress shows come from the confirmed items. Each state crossfades
// into the next in place.
import SwiftUI

struct ReviewSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var detent = PresentationDetent.medium
    /// The steps the last confirmed cleanup needs, for the progress list.
    @State private var plannedSteps: [CleanupStep] = []

    var body: some View {
        NavigationStack {
            content
                .transition(.opacity)
                .animation(Motion.quick, value: app.cleanup.state)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if !app.cleanup.isWorking {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close", action: close)
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(app.cleanup.isWorking)
        .onDisappear(perform: app.cleanup.dismissResult)
    }

    @ViewBuilder
    private var content: some View {
        switch app.cleanup.state {
        case .working(let step):
            CleanupProgressView(step: step, planned: plannedSteps)
        case .finished(let report):
            CleanupResultView(report: report, onDone: close)
        case .idle where app.review.isEmpty:
            EmptyStateView(mood: .resting, title: "Nothing to review", message: "Selected items wait here.")
        case .idle:
            ReviewList(totalSize: detent == .large ? .regular : .compact, onConfirm: cleanUp)
        }
    }

    private var title: String {
        switch app.cleanup.state {
        case .working: "Cleaning up"
        case .finished: "Summary"
        case .idle: "Review"
        }
    }

    /// Runs exactly what the confirmation named; the store ignores a second run while one is working.
    private func cleanUp(_ items: [BasketItem]) {
        plannedSteps = CleanupProgress.planned(for: ReviewSummary(items: items))
        Task { await app.cleanUp(items) }
    }

    private func close() {
        app.cleanup.dismissResult()
        dismiss()
    }
}
