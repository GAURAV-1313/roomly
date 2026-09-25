// Why: the one place with a destructive button. Everything that can run is listed by kind with a total, any
// item can be taken out, and the red button in the dock asks once more in words that say exactly what will
// happen. Items that can't run yet — photos without Photos access, merges Roomy can't see — wait in a note of
// their own: never as rows with made-up names, never in a count or the confirmation. The total shrinks at the
// medium detent so the first section still shows above the dock.
import SwiftUI

struct ReviewList: View {
    @Environment(AppState.self) private var app
    let totalSize: ReviewTotalCard.Size
    /// Runs exactly the items the confirmation named.
    let onConfirm: ([BasketItem]) -> Void

    @State private var isConfirming = false

    var body: some View {
        let review = app.review
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Space.s12) {
                if !review.ready.isEmpty {
                    ReviewTotalCard(
                        summary: ReviewSummary(items: review.ready), size: totalSize, isConfirming: isConfirming)
                }
                ReviewHoldNotes(review: review)
                ForEach(BasketItem.Kind.allCases, id: \.self) { kind in
                    ReviewSection(kind: kind, items: review.ready(of: kind))
                }
            }
            .padding(.horizontal, Space.margin)
            .padding(.top, Space.s4)
            .padding(.bottom, Space.s16)
        }
        .background(RoomyColor.sheet)
        .bottomBar {
            if !review.ready.isEmpty {
                ReviewDeleteDock(ready: review.ready, isConfirming: $isConfirming, onConfirm: onConfirm)
            }
        }
    }
}
