// Why: the result opens in the dashboard's hero card. First "moved", with an amber pin on the usage bar saying the
// space is in Recently Deleted, because it isn't free yet; then, once free space is measured again and has risen
// by about that much, the measured rise with the pin turned green. Roomy stands alone when only contacts changed or
// no size is known, because "0 KB" would be made up. The title and lead sit in the white card below.
import SwiftUI

struct ResultHeroCard: View {
    @Environment(AppState.self) private var app
    let summary: ResultSummary

    private var report: CleanupReport { summary.report }

    var body: some View {
        VStack(spacing: Space.s8) {
            hero
            words
        }
        .padding(.top, Layout.heroTopInset)
        .padding([.horizontal, .bottom], Layout.heroInset)
        .heroShell()
    }

    /// One branch for both stages, so the same bar stays on screen and its pin turns green in place instead of
    /// being replaced and dropping again.
    @ViewBuilder
    private var hero: some View {
        if let amount = heroAmount {
            hero(value: amount.value, label: amount.label, marker: amount.marker)
        } else {
            // With every size unavailable there is no number to draw, and "0 KB" would be made up.
            MascotView(mood: summary.mood, size: MascotSize.emptyState)
        }
    }

    private var heroAmount: (value: String, label: String, marker: StorageMarker)? {
        switch summary.stage {
        case .waiting where report.removedBytes > 0:
            (report.removedBytes.byteString, "not freed yet", .pending(report.removedBytes))
        case .reclaimed(let bytes):
            (bytes.byteString, "more free space", .freed(bytes))
        case .waiting, .mergedOnly, .unchanged:
            nil
        }
    }

    private var words: some View {
        VStack(spacing: Space.s8) {
            Text(summary.title)
                .font(RoomyFont.title2)
                .foregroundStyle(RoomyColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let lead = summary.lead {
                Text(lead).font(RoomyFont.body).foregroundStyle(RoomyColor.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(Space.s20)
        .heroInnerCard()
    }

    /// Removed space is still on the phone, so the bar's used share includes it until Recently Deleted is emptied;
    /// the pin marks it instead of carving it out.
    private func hero(value: String, label: String, marker: StorageMarker) -> some View {
        let usage = StorageUsage(volume: app.volume)
        return StorageHero(
            value: value, label: label, mood: summary.mood, usageTitle: usage.title, usageDetail: usage.detail,
            usedFraction: usage.usedFraction, marker: marker)
    }
}
