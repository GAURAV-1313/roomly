// Why: the two-stage result. The hero says what moved or what was measured; every other outcome is its own row,
// so a partial result reads as a list and never hides what it didn't do. While items wait in Recently Deleted,
// the exact way to finish the job in Photos follows, and Open Photos and Done stay pinned in a dock so the next
// step is always in reach. Apps cannot empty Recently Deleted, so Roomy never pretends to.
import SwiftUI

struct CleanupResultView: View {
    @Environment(AppState.self) private var app
    let report: CleanupReport
    let onDone: () -> Void

    private var summary: ResultSummary {
        ResultSummary(report: report, reclaimedBytes: app.cleanup.reclaimedBytes)
    }

    var body: some View {
        let summary = summary
        ScrollView {
            VStack(spacing: Space.s16) {
                ResultHeroCard(summary: summary)
                notes(summary.lines)
                if summary.stage == .waiting {
                    RecentlyDeletedSteps()
                }
            }
            .padding(.horizontal, Space.margin)
            .padding(.vertical, Space.s8)
        }
        .background(RoomyColor.bg)
        .bottomBar { actions(summary.stage) }
        .onAppear { Haptics.success() }
    }

    @ViewBuilder
    private func notes(_ lines: [ResultLine]) -> some View {
        if !lines.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                    if index > 0 {
                        Rectangle().fill(RoomyColor.separator).frame(height: 1)
                    }
                    ResultNoteRow(line: line)
                }
            }
            .padding(.horizontal, Space.s16)
            .padding(.vertical, Space.s4)
            .frame(maxWidth: .infinity)
            .dashboardCard()
        }
    }

    private func actions(_ stage: ResultSummary.Stage) -> some View {
        VStack(spacing: Space.s8) {
            if stage == .waiting {
                Button("Open Photos", systemImage: "photo.on.rectangle.angled", action: PhotosApp.open)
                    .buttonStyle(.roomyPrimary)
                Button("Done", action: onDone).buttonStyle(.roomySecondary)
            } else {
                Button("Done", action: onDone).buttonStyle(.roomyPrimary)
            }
        }
        .padding(.horizontal, Space.margin)
        .padding(.top, Space.s16)
        .padding(.bottom, Space.s12)
    }
}
