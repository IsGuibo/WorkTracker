import XCTest
@testable import WorkTracker

final class CalendarHelperTests: XCTestCase {
    func testParseAndFormat() {
        let date = DateHelpers.parse("2026-03-14")
        XCTAssertNotNil(date)
        XCTAssertEqual(DateHelpers.format(date!), "2026-03-14")
    }

    func testDaysInMonth() {
        XCTAssertEqual(DateHelpers.daysInMonth(year: 2026, month: 2), 28)
        XCTAssertEqual(DateHelpers.daysInMonth(year: 2026, month: 3), 31)
    }

    func testFirstWeekday() {
        // 2026-03-01 是周日
        let weekday = DateHelpers.firstWeekdayOfMonth(year: 2026, month: 3)
        XCTAssertEqual(weekday, 1) // Sunday = 1
    }
}
