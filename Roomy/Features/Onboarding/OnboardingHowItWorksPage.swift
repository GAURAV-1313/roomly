// Why: before anything is asked, the person sees the whole path — find, review, delete, empty Recently Deleted —
// as one connected rail, so the last step is no surprise: removed is not freed until Recently Deleted is emptied.
// That truth gets one quiet sentence, not a warning. The rail's last step is green because only it frees space.
import SwiftUI

struct OnboardingHowItWorksPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.s24) {
            VStack(alignment: .leading, spacing: Space.s4) {
                Text("How Roomy cleans up")
                    .font(RoomyFont.title1)
                    .foregroundStyle(RoomyColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Four steps. You decide at every one.")
                    .font(RoomyFont.body)
                    .foregroundStyle(RoomyColor.textSecondary)
            }
            rail
            explainer
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var rail: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                StepRailRow(step: step, isLast: step == OnboardingStep.allCases.last)
            }
        }
        .padding(.top, Space.s20)
        .padding(.horizontal, Space.s16)
        .padding(.bottom, Space.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }

    /// The sentence's first words carry it, so they read in the primary colour.
    private var lead: Text {
        Text("Removed is not freed yet.").fontWeight(.semibold).foregroundStyle(RoomyColor.textPrimary)
    }

    private var explainer: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s8) {
            Image(systemName: "info.circle").foregroundStyle(RoomyColor.textSecondary)
            Text(
                "\(lead) Photos keeps deleted items in Recently Deleted until you empty it, and Roomy shows you how."
            )
            .foregroundStyle(RoomyColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .font(RoomyFont.footnote)
        .padding(.horizontal, Space.s4)
    }
}

/// The four steps, in order, with their words and glyphs.
nonisolated enum OnboardingStep: Int, CaseIterable, Sendable {
    case find
    case review
    case delete
    case empty

    /// "01" to "04": the rail's index beside each title.
    var index: String { String(format: "%02d", rawValue + 1) }

    var title: String {
        switch self {
        case .find: "Find"
        case .review: "Review"
        case .delete: "Delete"
        case .empty: "Empty Recently Deleted"
        }
    }

    var message: String {
        switch self {
        case .find: "Similar photos, screenshots, big videos and duplicate contacts."
        case .review: "You pick what goes. Nothing is picked for you."
        case .delete: "iOS asks you to confirm. Photos go to Recently Deleted."
        case .empty: "In Photos. Only then is the space free."
        }
    }

    var systemImage: String {
        switch self {
        case .find: "magnifyingglass"
        case .review: "checklist"
        case .delete: "trash"
        case .empty: "internaldrive"
        }
    }
}

/// One step: a soft circle on the rail, joined to the next by a line, and the numbered title and message.
private struct StepRailRow: View {
    let step: OnboardingStep
    let isLast: Bool

    private var tint: Color { step == .empty ? RoomyColor.success : RoomyColor.accent }
    private var soft: Color { step == .empty ? RoomyColor.successSoft : RoomyColor.accentSoft }

    var body: some View {
        HStack(alignment: .top, spacing: Layout.railGap) {
            VStack(spacing: Space.s4) {
                Image(systemName: step.systemImage)
                    .font(.system(size: Layout.railGlyph, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: Layout.railNode, height: Layout.railNode)
                    .background(soft, in: Circle())
                if !isLast {
                    Rectangle().fill(RoomyColor.separator).frame(width: Layout.railLine).frame(maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)
            text
        }
        // Sized to the text, so the rail line below the circle stretches exactly to the next step.
        .fixedSize(horizontal: false, vertical: true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            HStack(spacing: Space.s8) {
                Text(step.index).font(RoomyFont.footnoteSemibold).foregroundStyle(tint)
                Text(step.title).font(RoomyFont.subheadlineSemibold).foregroundStyle(RoomyColor.textPrimary)
            }
            Text(step.message).font(RoomyFont.footnote).foregroundStyle(RoomyColor.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Layout.railTextTop)
        .padding(.bottom, Layout.railTextBottom)
        .accessibilityElement(children: .combine)
    }
}
