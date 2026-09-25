// Why: several screens group items under month headers. One implementation keeps the order and the
// month titles identical everywhere.
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

    static func title(for date: Date?) -> String {
        guard let date else { return "Undated" }
        return date.formatted(.dateTime.month(.wide).year())
    }
}
