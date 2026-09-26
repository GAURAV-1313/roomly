// Why: the Photos idiom people already know — a tight four-column grid under month headers. Each month folds to
// one row with its own toggle ("Select 24"), the newest open, so a whole month is selected without scrolling
// through it; "Select all" beside Review takes every screenshot shown. A tap adds to or removes from the basket;
// nothing is deleted here. Screenshots often hold tickets, codes or receipts, so a long press shows one large
// first. The numbers sit under the title; at accessibility text sizes the grid drops to three columns so the
// tiles stay recognisable.
import SwiftUI

struct ScreenshotsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Months the person folded; seeded once with the default, kept while the screen is on the stack.
    @State private var collapsed: Set<String> = []

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? Layout.screenshotColumnsAccessible : Layout.screenshotColumns
        return Array(repeating: GridItem(.flexible(), spacing: Layout.screenshotGutter), count: count)
    }

    var body: some View {
        content
            .navigationTitle("Screenshots")
            .navigationBarTitleDisplayMode(.large)
            .reviewBar(bulk: bulkSelection)
    }

    private var bulkSelection: BulkSelection? {
        let screenshots = app.scan.screenshots
        let state = PhotoScanGateState.make(
            access: app.photoAccess.state, phase: app.scan.phase, isEmpty: screenshots.isEmpty, needsComparison: false)
        guard state.showsContent else { return nil }
        return BulkSelection(isAllSelected: app.basket.containsAll(screenshots.map(\.id))) { [app] in
            app.basket.toggleAll(screenshots)
        }
    }

    private var content: some View {
        PhotoScanGate(
            isEmpty: app.scan.screenshots.isEmpty, emptyTitle: "All clear",
            emptyMessage: "No screenshots here. Roomy will keep an eye out.",
            tint: Route.screenshots.categoryTintSoft
        ) {
            screenshotList
        } placeholder: {
            ScreenshotsSkeleton(columns: columns)
        }
    }

    private var screenshotList: some View {
        let screenshots = app.scan.screenshots
        let sections = MonthSections.make(screenshots, date: \.creationDate)
        let folding = MonthFolding(ids: sections.map(\.id), collapsed: collapsed)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: Space.s12, pinnedViews: .sectionHeaders) {
                CategorySubtitle(
                    route: .screenshots, systemImage: "camera.viewfinder",
                    text: ScreenshotsSummary(count: screenshots.count, size: screenshots.sizeTotal).subtitle)
                if folding.showsFoldAllRow {
                    MonthFoldAllRow(folding: folding) { fold(to: folding.afterFoldAll) }
                }
                ForEach(sections) { section in
                    Section {
                        if folding.isOpen(section.id) {
                            grid(section.items).transition(rowTransition)
                        }
                    } header: {
                        header(for: section, folding: folding)
                    }
                }
            }
            .padding(.horizontal, Space.margin)
            .padding(.bottom, Layout.bottomBarClearance)
        }
        .background(RoomyColor.bg)
        .foldingOlderMonths(sections.map(\.id), into: $collapsed)
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

    private func header(for section: MonthSection<AssetSnapshot>, folding: MonthFolding) -> some View {
        let month = MonthSummary.screenshots(
            month: section.title, count: section.items.count,
            selectedCount: section.items.filter { app.basket.contains($0.id) }.count, size: section.items.sizeTotal)
        return MonthHeader(
            month: month, isOpen: folding.isOpen(section.id),
            onToggleOpen: { fold(to: folding.toggling(section.id)) },
            onToggleSelection: { app.basket.toggleAll(section.items) })
    }

    private func fold(to newCollapsed: Set<String>) {
        withAnimation(reduceMotion ? Motion.quick : Motion.disclose) {
            collapsed = newCollapsed
        }
    }

    /// The grid slides down from its month as it opens; with Reduce Motion it only fades.
    private var rowTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top))
    }
}
