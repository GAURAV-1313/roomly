// Why: several screens group items under month headers. One implementation keeps the order, the month titles
// and which months start folded identical everywhere. The newest month holds the fresh bursts and duplicates,
// so it opens; once there are more than two months the older ones fold to one row each, so every month's bulk
// action is in reach without scrolling through the months above it.
import Foundation

nonisolated struct MonthSection<Item>: Identifiable {
    let title: String
    let items: [Item]
    var id: String { title }
}

nonisolated enum MonthSections {
    /// Groups items by month title, keeping the order in which each month first appears.
    static func make<Item>(_ items: [Item], date: (Item) -> Date?) -> [MonthSection<Item>] {
        var order: [String] = []
        var buckets: [String: [Item]] = [:]
        for item in items {
            let title = title(for: date(item))
            if buckets[title] == nil {
                order.append(title)
            }
            buckets[title, default: []].append(item)
        }
        return order.map { MonthSection(title: $0, items: buckets[$0] ?? []) }
    }

    /// Up to this many months all start open; with more, only the first (newest) does.
    static let openMonthLimit = 2

    /// The months that start folded, given month ids newest first.
    static func defaultCollapsed(_ ids: [String]) -> Set<String> {
        guard ids.count > openMonthLimit else { return [] }
        return Set(ids.dropFirst())
    }

    static func title(for date: Date?) -> String {
        guard let date else { return "Undated" }
        return date.formatted(.dateTime.month(.wide).year())
    }
}
