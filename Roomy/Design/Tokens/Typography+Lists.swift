// Why: the fixed contact card has two small labels of its own: the "from card 2" tag on a merged value's label
// line, below the chips' footnote so it stays one line beside the label, and the number in each member card's
// circle. They are text styles like every other font, so they scale.
import SwiftUI

extension RoomyFont {
    static let captionSemibold = Font.caption.weight(.semibold)
    static let caption2Semibold = Font.caption2.weight(.semibold)
}
