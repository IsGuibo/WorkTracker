import XCTest
@testable import WorkTracker

final class CalendarMonthViewTests: XCTestCase {
    func testWeekBarIDUsesFullSpanToAvoidCollision() {
        let first = CalendarMonthView.WeekBar(
            projectId: "p7",
            name: "中欧 数据接入",
            isDone: false,
            startCol: 1,
            endCol: 1,
            lane: 2,
            startDay: 23
        )
        let second = CalendarMonthView.WeekBar(
            projectId: "p7",
            name: "中欧 数据接入",
            isDone: false,
            startCol: 1,
            endCol: 2,
            lane: 2,
            startDay: 23
        )

        XCTAssertNotEqual(first.id, second.id)
    }

    func testMergeOverlappingSegmentsCollapsesSameDayOverlap() {
        let merged = CalendarMonthView.mergeOverlappingSegments([
            (startDay: 16, endDay: 18),
            (startDay: 23, endDay: 23),
            (startDay: 23, endDay: 24)
        ])

        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged[0].startDay, 16)
        XCTAssertEqual(merged[0].endDay, 18)
        XCTAssertEqual(merged[1].startDay, 23)
        XCTAssertEqual(merged[1].endDay, 24)
    }
}
