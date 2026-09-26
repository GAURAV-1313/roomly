// Why: loading skeletons (Figma "Loading states v5") stand in for real text and rows, so their sizes are the
// sizes of what they hold the place of. They live beside the other layout tokens so a skeleton and the view it
// replaces change together.
import SwiftUI

extension Layout {
    /// A skeleton line standing in for footnote text.
    static let skeletonTextHeight: CGFloat = 10
    /// A skeleton line standing in for a heading.
    static let skeletonTitleHeight: CGFloat = 14
    static let skeletonDetailWidth: CGFloat = 90
    /// The storage card's amount while the first index is read.
    static let heroValueSkeleton = CGSize(width: 96, height: 22)
    /// The tinted well holding Roomy on the comparison's progress card (Figma "ProgressCard v5").
    static let progressWell: CGFloat = 64
    /// Similar Photos while comparing: a month header, then each group's header, filmstrip and footer lines.
    static let skeletonMonthWidth: CGFloat = 110
    static let skeletonGroupHeaderWidth: CGFloat = 120
    static let skeletonGroupFooterWidth: CGFloat = 180
    static let skeletonGroupCount = 2
    static let skeletonGroupTiles = 3
    /// Large Videos while indexing: rows with a filename line and a detail line.
    static let skeletonFilenameWidth: CGFloat = 150
    static let skeletonVideoRows = 4
    /// Screenshots while indexing: this many rows of the grid.
    static let skeletonScreenshotRows = 3
}
