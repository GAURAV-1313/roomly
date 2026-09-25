// Why: turning "these two photos match" pairs into groups is the classic disjoint-set problem.
// Path halving keeps `find` near constant time, so grouping stays linear in practice.
import Foundation

nonisolated struct UnionFind {
    private var parent: [Int]

    init(count: Int) {
        parent = Array(0..<count)
    }

    mutating func find(_ element: Int) -> Int {
        var current = element
        while parent[current] != current {
            parent[current] = parent[parent[current]]
            current = parent[current]
        }
        return current
    }

    mutating func union(_ first: Int, _ second: Int) {
        let firstRoot = find(first)
        let secondRoot = find(second)
        if firstRoot != secondRoot {
            parent[secondRoot] = firstRoot
        }
    }
}
