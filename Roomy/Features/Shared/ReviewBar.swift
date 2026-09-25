// Why: every category screen offers the same way into Review: a glass capsule that appears whenever anything is
// saved for Review and counts only what can really run. Items on hold still bring it up, quietly, because Review
// is the only place that says why they wait and lets the person fix that or take them out. One modifier means
// one entry point to the only screen where anything can be deleted. The capsule rises in from the bottom when
// the first item is saved and sinks away when the last one goes; with Reduce Motion it only fades. The
// dashboard draws the same capsule, title and sheet inside its own state-driven bar (DashboardActionBar).
import SwiftUI

struct ReviewBar: ViewModifier {
    @Environment(AppState.self) private var app

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isReviewing = false

    func body(content: Content) -> some View {
        content
            .bottomBar {
                let review = app.review
                VStack(spacing: 0) {
                    if let title = review.barTitle {
                        BottomActionBar(title: title, isProminent: !review.ready.isEmpty) {
                            isReviewing = true
                        }
                        .transition(capsuleTransition)
                    }
                }
                .animation(Motion.standard, value: review.barTitle == nil)
            }
            .sheet(isPresented: $isReviewing) {
                ReviewSheet().environment(app)
            }
    }
}

extension ReviewBar {
    private var capsuleTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }
}

extension View {
    func reviewBar() -> some View {
        modifier(ReviewBar())
    }
}
