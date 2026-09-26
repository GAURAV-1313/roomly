// Why: beside a bulk action the Review capsule has half the width, so it shortens to "Review 8 · 11.9 MB" while
// VoiceOver keeps the full words. What the capsule says, and whether it shows at all, is decided here as a pure
// value from the review, so the short and the long title can never disagree about the count. Items on hold still
// bring it up, quietly, because Review is the only place that says why they wait.
import Foundation

nonisolated struct ReviewBarModel: Equatable {
    let review: BasketReview
    /// True when the screen shows its bulk action beside the capsule.
    let hasBulkAction: Bool

    /// The capsule's visible title; nil when there is nothing to review and the capsule hides.
    var title: String? {
        guard hasBulkAction, !review.ready.isEmpty else { return review.barTitle }
        let bytes = review.readyBytes
        guard bytes > 0 else { return "Review \(review.ready.count.counted("item"))" }
        return "Review \(review.ready.count.formatted()) · \(bytes.byteString)"
    }

    /// The full words, read by VoiceOver: "Review 8 items · 11.9 MB".
    var accessibilityLabel: String? { review.barTitle }

    /// Filled only when something can really run; items on hold alone keep it quiet.
    var isProminent: Bool { !review.ready.isEmpty }
}
