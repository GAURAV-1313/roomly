// Why: under the player, the three facts that matter when deciding — when, how sharp, how big — as a white
// card of rows with inset separators (Figma "VideoFacts v5"). When the title and value no longer fit side by
// side at large text sizes, each row stacks the value under its title instead of truncating either.
import SwiftUI

struct VideoFactsCard: View {
    let facts: [VideoFact]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(facts) { fact in
                if fact.id != facts.first?.id {
                    Rectangle()
                        .fill(RoomyColor.separator)
                        .frame(height: 1)
                        .padding(.horizontal, Space.s8)
                }
                FactRow(fact: fact)
            }
        }
        .padding(.vertical, Space.s4)
        .frame(maxWidth: .infinity)
        .dashboardCard()
    }
}

private struct FactRow: View {
    let fact: VideoFact

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.s12) {
                title
                Spacer(minLength: 0)
                value.fixedSize()
            }
            VStack(alignment: .leading, spacing: Space.s2) {
                title
                value
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(RoomyFont.subheadline)
        .padding(.horizontal, Space.s16)
        .padding(.vertical, Space.s8)
        .accessibilityElement(children: .combine)
    }

    private var title: some View {
        Text(fact.title).foregroundStyle(RoomyColor.textSecondary)
    }

    private var value: some View {
        Text(fact.value).fontWeight(.semibold).foregroundStyle(RoomyColor.textPrimary)
    }
}
