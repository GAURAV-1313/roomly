// Why: size is the sort key, so this is a list with a right-aligned size column, not a grid. Tap a row
// to select it; tap the poster to watch it first. The line under the title always describes the list under it,
// and the "Over 500 MB" chip is the screen's one filter. "Select all" beside Review takes exactly the videos
// the list shows, never ones the filter hides.
import SwiftUI

struct LargeVideosView: View {
    @Environment(AppState.self) private var app
    @State private var playing: AssetSnapshot?
    @State private var showsLargeOnly = false

    private var summary: VideoListSummary {
        VideoListSummary(videos: app.scan.videos, showsLargeOnly: showsLargeOnly)
    }

    var body: some View {
        let summary = summary
        content(summary)
            .navigationTitle("Large Videos")
            .navigationBarTitleDisplayMode(.large)
            .reviewBar(bulk: bulkSelection(summary))
            .sheet(item: $playing) { video in
                VideoPlayerSheet(video: video)
                    .environment(app)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }

    private func bulkSelection(_ summary: VideoListSummary) -> BulkSelection? {
        let visible = summary.visible
        let state = PhotoScanGateState.make(
            access: app.photoAccess.state, phase: app.scan.phase, isEmpty: app.scan.videos.isEmpty,
            needsComparison: false)
        guard state.showsContent, !visible.isEmpty else { return nil }
        return BulkSelection(isAllSelected: app.basket.containsAll(visible.map(\.id))) { [app] in
            app.basket.toggleAll(visible)
        }
    }

    private func content(_ summary: VideoListSummary) -> some View {
        PhotoScanGate(
            isEmpty: app.scan.videos.isEmpty, emptyTitle: "No large videos",
            emptyMessage: "Nothing here takes up much room. Roomy will keep an eye out.",
            tint: Route.largeVideos.categoryTintSoft
        ) {
            ScrollView {
                LazyVStack(spacing: Space.s12) {
                    header(summary)
                    if summary.isFilterHidingEverything {
                        noLargeVideosCard
                    }
                    ForEach(summary.visible) { video in
                        VideoRow(
                            video: video, isSelected: app.basket.contains(video.id),
                            onSelect: { toggle(video) }, onPlay: { playing = video })
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.bottom, Layout.bottomBarClearance)
            }
            .background(RoomyColor.bg)
        } placeholder: {
            VideoRowsSkeleton()
        }
    }

    private func header(_ summary: VideoListSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CategorySubtitle(route: .largeVideos, systemImage: "film.stack", text: summary.subtitle)
            FilterChip(title: "Over 500 MB", isOn: $showsLargeOnly)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noLargeVideosCard: some View {
        VStack(spacing: Space.s8) {
            Text("No videos over 500 MB")
                .font(RoomyFont.headline)
                .foregroundStyle(RoomyColor.textPrimary)
            Text("Every video here is smaller, or Photos didn't report its size.")
                .font(RoomyFont.subheadline)
                .foregroundStyle(RoomyColor.textSecondary)
            Button("Show All Videos") { showsLargeOnly = false }
                .buttonStyle(.roomySecondary)
                .controlSize(.small)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(Space.s20)
        .frame(maxWidth: .infinity)
        .dashboardCard()
    }

    private func toggle(_ video: AssetSnapshot) {
        Haptics.tap()
        app.basket.toggle(video)
    }
}
