// Why: a big contact group shows its first three cards and says how many more there are, so the merge result
// stays in view. These tests pin the cut and the words.
import XCTest

@testable import Roomy

final class MemberListTests: XCTestCase {
    private func members(_ count: Int) -> [MergeMember] {
        (1...count).map { MergeMember(number: $0, name: "Card \($0)", values: []) }
    }

    func testThreeOrFewerCardsAllShow() {
        let list = MemberList(members: members(3), isExpanded: false)
        XCTAssertEqual(list.visible.map(\.number), [1, 2, 3])
        XCTAssertNil(list.moreLabel)
    }

    func testMoreCardsWaitBehindACountThatOpensInPlace() {
        XCTAssertEqual(MemberList(members: members(4), isExpanded: false).moreLabel, "+1 more card")
        let five = MemberList(members: members(5), isExpanded: false)
        XCTAssertEqual(five.visible.map(\.number), [1, 2, 3])
        XCTAssertEqual(five.moreLabel, "+2 more cards")
        let open = MemberList(members: members(5), isExpanded: true)
        XCTAssertEqual(open.visible.count, 5)
        XCTAssertNil(open.moreLabel)
    }
}
