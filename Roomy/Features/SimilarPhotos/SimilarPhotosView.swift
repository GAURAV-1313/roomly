// Why: Apple's own duplicates idiom — groups, a marked keeper, a visible reason so people can check the
// grouping, and Compare for the full-screen decision. Nothing is selected until the person chooses: "Select
// all" beside Review selects every suggested extra, a month's toggle selects that month's, or they pick per
// group. A favourite or a burst frame the person picked is never selected in bulk; it can still be picked by
// hand, and no bulk action ever selects a keeper. Months fold, the newest open, so any month's toggle is in
// reach without scrolling through the others. The numbers sit under the title; the honest note about photos
// Roomy couldn't compare closes the list.
import SwiftUI

struct SimilarPhotosView: View {
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var comparing: SimilarGroup?
    /// Months the person folded; seeded once with the default, kept while the screen is on the stack.
    @State private var collapsed: Set<String> = []

    var body: some View {
        content
            .navigationTitle("Similar Photos")
            .navigationBarTitleDisplayMode(.large)
            .reviewBar(bulk: bulkSelection)
            .fullScreenCover(item: $comparing) { group in
                CompareView(group: group).environment(app)
            }
    }

    private var copy: SimilarPhotosCopy { SimilarPhotosCopy(uncheckedCount: app.scan.uncheckedPhotoCount) }

    private var gateState: PhotoScanGateState {
        .make(
            access: app.photoAccess.state, phase: app.scan.phase, isEmpty: app.scan.similarGroups.isEmpty,
            needsComparison: true)
    }

    /// Every suggested extra on screen, never a keeper or a photo the person marked in Photos.
    private var bulkSelection: BulkSelection? {
        let extras = app.scan.suggestedExtras
        guard gateState.showsContent, !extras.isEmpty else { return nil }
        return BulkSelection(isAllSelected: app.basket.containsAll(extras), noun: "extras") { [app] in
            app.basket.toggleAll(app.scan.snapshots(extras))
        }
    }

    private var content: some View {
        let groups = app.scan.similarGroups
        return PhotoScanGate(
            isEmpty: groups.isEmpty, emptyTitle: copy.emptyTitle, emptyMessage: copy.emptyMessage,
            needsComparison: true, tint: Route.similarPhotos.categoryTintSoft
        ) {
            groupList(groups)
        } placeholder: {
            SimilarGroupsSkeleton(copy: ScanProgressCopy(phase: app.scan.phase, hashProgress: app.scan.hashProgress))
        }
    }

    private func groupList(_ groups: [SimilarGroup]) -> some View {
        let sections = MonthSections.make(groups, date: \.date)
        let folding = MonthFolding(ids: sections.map(\.id), collapsed: collapsed)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: Space.s12, pinnedViews: .sectionHeaders) {
                CategorySubtitle(route: .similarPhotos, systemImage: "photo.stack", text: subtitle(groups))
                if folding.showsFoldAllRow {
                    MonthFoldAllRow(folding: folding) { fold(to: folding.afterFoldAll) }
                }
                ForEach(sections) { section in
                    Section {
                        if folding.isOpen(section.id) {
                            ForEach(section.items) { group in
                                SimilarGroupCard(group: group) { comparing = group }
                                    .transition(rowTransition)
                            }
                        }
                    } header: {
                        monthHeader(section, folding: folding)
                    }
                }
                if let note = copy.uncheckedNote {
                    ListFootnote(text: note)
                }
            }
            .padding(.horizontal, Space.margin)
            .padding(.bottom, Layout.bottomBarClearance)
        }
        .background(RoomyColor.bg)
        .foldingOlderMonths(sections.map(\.id), into: $collapsed)
    }

    private func subtitle(_ groups: [SimilarGroup]) -> String {
        SimilarPhotosSummary(
            groupCount: groups.count, extraCount: app.scan.suggestedExtras.count, size: app.scan.similarSize
        ).subtitle
    }

    private func monthHeader(_ section: MonthSection<SimilarGroup>, folding: MonthFolding) -> some View {
        let extras = section.items.flatMap(\.suggestedExtras)
        let month = MonthSummary.similar(
            month: section.title, groupCount: section.items.count, extraCount: extras.count,
            selectedCount: extras.filter(app.basket.contains).count, size: app.scan.sizeTotal(of: extras))
        return MonthHeader(
            month: month, isOpen: folding.isOpen(section.id),
            onToggleOpen: { fold(to: folding.toggling(section.id)) },
            onToggleSelection: { app.basket.toggleAll(app.scan.snapshots(extras)) })
    }

    private func fold(to newCollapsed: Set<String>) {
        withAnimation(reduceMotion ? Motion.quick : Motion.disclose) {
            collapsed = newCollapsed
        }
    }

    /// Rows slide down from their month as it opens; with Reduce Motion they only fade.
    private var rowTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top))
    }
}
