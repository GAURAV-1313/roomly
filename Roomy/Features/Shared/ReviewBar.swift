// Why: every category screen offers the same way into Review: a glass capsule that appears whenever anything is
// saved for Review and counts only what can really run. Items on hold still bring it up, quietly, because Review
// is the only place that says why they wait and lets the person fix that or take them out. One modifier means
// one entry point to the only screen where anything can be deleted. A screen can pass its bulk action, which
// sits to the left of the capsule (Figma "Fix 5 · C"); with nothing saved it spans the bar alone. The bar rises in
// from the bottom when it first has something to show and sinks away when it has nothing; with Reduce Motion it
// only fades. The dashboard draws the same capsule, title and sheet inside its own bar (DashboardActionBar).
import SwiftUI

struct ReviewBar: ViewModifier {
    @Environment(AppState.self) private var app
    /// The screen's bulk action; nil when it has nothing to select.
    let bulk: BulkSelection?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isReviewing = false

    func body(content: Content) -> some View {
        content
            .bottomBar {
                let model = ReviewBarModel(review: app.review, hasBulkAction: bulk != nil)
                let primary = reviewAction(model)
                let leading = bulk.map(bulkAction)
                VStack(spacing: 0) {
                    if primary != nil || leading != nil {
                        BottomActionBar(leading: leading, primary: primary)
                            .transition(barTransition)
                    }
                }
                .animation(Motion.standard, value: primary == nil && leading == nil)
            }
            .sheet(isPresented: $isReviewing) {
                ReviewSheet().environment(app)
            }
    }
}

extension ReviewBar {
    private func reviewAction(_ model: ReviewBarModel) -> BottomBarAction? {
        guard let title = model.title else { return nil }
        return BottomBarAction(
            title: title, isProminent: model.isProminent, accessibilityLabel: model.accessibilityLabel
        ) {
            isReviewing = true
        }
    }

    private func bulkAction(_ bulk: BulkSelection) -> BottomBarAction {
        BottomBarAction(
            title: bulk.title, systemImage: bulk.systemImage, accessibilityLabel: bulk.accessibilityLabel
        ) {
            Haptics.tap()
            bulk.toggle()
        }
    }

    private var barTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }
}

extension View {
    /// The Review capsule, with the screen's bulk action beside it when there is one.
    func reviewBar(bulk: BulkSelection? = nil) -> some View {
        modifier(ReviewBar(bulk: bulk))
    }
}
