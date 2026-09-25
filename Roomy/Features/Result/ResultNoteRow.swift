// Why: one outcome of a cleanup per row, with an icon that says what kind it is. Good outcomes — a kept last
// photo, merged cards — sit on green; everything else on a neutral chip, because nothing here is the person's
// mistake and red is kept for the one delete button.
import SwiftUI

struct ResultNoteRow: View {
    let line: ResultLine

    var body: some View {
        HStack(alignment: .top, spacing: Space.s12) {
            Image(systemName: line.kind.glyph)
                .font(RoomyFont.footnoteSemibold)
                // The square has a fixed size, so its glyph stops growing where it would spill out.
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundStyle(line.kind.isGood ? RoomyColor.success : RoomyColor.textSecondary)
                .frame(width: Layout.sectionIcon, height: Layout.sectionIcon)
                .background(
                    line.kind.isGood ? RoomyColor.successSoft : RoomyColor.chip,
                    in: RoundedRectangle(cornerRadius: Radius.iconSquare, style: .continuous)
                )
                .accessibilityHidden(true)
            Text(line.text)
                .font(RoomyFont.subheadline)
                .foregroundStyle(RoomyColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Space.s8)
    }
}

extension ResultLine.Kind {
    var glyph: String {
        switch self {
        case .stopped: "hand.raised.fill"
        case .notFound: "exclamationmark.circle.fill"
        case .kept: "checkmark.seal.fill"
        case .held: "pause.circle"
        case .merged: "person.2.fill"
        case .contactsLeft: "exclamationmark.triangle.fill"
        }
    }

    var isGood: Bool { self == .kept || self == .merged }
}
