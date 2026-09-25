// Why: the Photos idiom people already know — a tight four-column grid under month headers, with "Select
// N" per month and Select All for the whole screen. A tap adds to or removes from the basket; nothing is
// deleted here. Screenshots often hold tickets, codes or receipts, so a long press shows one large first.
// The screen opens with the same summary card as every category; at accessibility text sizes the grid drops
// to three columns so the tiles stay recognisable.
import SwiftUI

struct ScreenshotsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? Layout.screenshotColumnsAccessible : Layout.screenshotColumns
        return Array(repeating: GridItem(.flexible(), spacing: Layout.screenshotGutter), count: count)
    }

    var body: some View {
        content
            .navigationTitle("Screenshots")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SelectAllButton(items: app.scan.screenshots) }
            }
            .reviewBar()
    }

    private var content: some View {
        PhotoScanGate(
            isEmpty: app.scan.screenshots.isEmpty, emptyTitle: "All clear",
            emptyMessage: "No screenshots here. Roomy will keep an eye out.",
            tint: Route.screenshots.categoryTintSoft
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Space.s12, pinnedViews: .sectionHeaders) {
                    summaryCard
                    ForEach(MonthSections.make(app.scan.screenshots, date: \.creationDate)) { section in
                        Section {
                            grid(section.items)
                        } header: {
                            header(for: section)
                        }
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.bottom, Layout.bottomBarClearance)
            }
            .background(RoomyColor.bg)
        } placeholder: {
            ScreenshotsSkeleton(columns: columns)
        }
    }

    private var summaryCard: some View {
        let screenshots = app.scan.screenshots
        let summary = ScreenshotsSummary(count: screenshots.count, size: screenshots.sizeTotal)
        return CategorySummaryCard(
            route: .screenshots, systemImage: "camera.viewfinder", value: summary.value, detail: summary.detail)
    }

    private func grid(_ shots: [AssetSnapshot]) -> some View {
        LazyVGrid(columns: columns, spacing: Layout.screenshotGutter) {
            ForEach(shots) { shot in tile(for: shot) }
        }
    }

    private func tile(for shot: AssetSnapshot) -> some View {
        let isSelected = app.basket.contains(shot.id)
        return Button {
            toggle(shot)
        } label: {
            ScreenshotTile(id: shot.id, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(isSelected ? "Remove from Review" : "Add to Review") { toggle(shot) }
        } preview: {
            AssetPreview(shot).environment(app)
        }
    }

    private func toggle(_ shot: AssetSnapshot) {
        Haptics.tap()
        app.basket.toggle(shot)
    }

    private func header(for section: MonthSection<AssetSnapshot>) -> some View {
        let isAllSelected = app.basket.containsAll(section.items.map(\.id))
        return SectionHeader(
            title: section.title,
            detail: ScreenshotsSummary.monthDetail(count: section.items.count, size: section.items.sizeTotal),
            action: isAllSelected ? "Deselect" : "Select \(section.items.count)", style: .month
        ) {
            app.basket.toggleAll(section.items)
        }
        .background(RoomyColor.bg)
    }
}
