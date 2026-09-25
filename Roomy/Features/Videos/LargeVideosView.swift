// Why: size is the sort key, so this is a list with a right-aligned size column, not a grid. Tap a row
// to select it; tap the poster to watch it first. The summary card always describes the list under it, and
// its "Over 500 MB" switch is the screen's one filter. Select All sits in the bar only while there is a list.
import SwiftUI

struct LargeVideosView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var playing: AssetSnapshot?
    @State private var showsLargeOnly = false

    private var summary: VideoListSummary {
        VideoListSummary(videos: app.scan.videos, showsLargeOnly: showsLargeOnly)
    }

    var body: some View {
        content(summary)
            .navigationTitle("Large Videos")
            .navigationBarTitleDisplayMode(.large)
            .reviewBar()
            .sheet(item: $playing) { video in
                VideoPlayerSheet(video: video)
                    .environment(app)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
                    summaryCard(summary)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SelectAllButton(items: summary.visible) }
            }
        } placeholder: {
            VideoRowsSkeleton()
        }
    }

    private func summaryCard(_ summary: VideoListSummary) -> some View {
        CategorySummaryCard(
            route: .largeVideos, systemImage: "film.stack", value: summary.value, detail: summary.detail
        ) {
            if dynamicTypeSize.isAccessibilitySize {
                // At accessibility sizes the switch drops under its label instead of squeezing it.
                VStack(alignment: .leading, spacing: Space.s8) {
                    filterLabel.accessibilityHidden(true)
                    Toggle(isOn: $showsLargeOnly) { filterLabel }.labelsHidden()
                }
            } else {
                Toggle(isOn: $showsLargeOnly) { filterLabel }
            }
        }
        .toggleStyle(.switch)
        .tint(RoomyColor.accent)
    }

    private var filterLabel: some View {
        Text("Over 500 MB").font(RoomyFont.subheadline).foregroundStyle(RoomyColor.textPrimary)
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
