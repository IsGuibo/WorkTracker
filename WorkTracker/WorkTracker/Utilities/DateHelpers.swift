import Foundation

enum DateHelpers {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func parse(_ string: String) -> Date? {
        formatter.date(from: string)
    }

    static func format(_ date: Date) -> String {
        formatter.string(from: date)
    }

    static func today() -> String {
        format(Date())
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    static func firstWeekdayOfMonth(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { return 1 }
        return calendar.component(.weekday, from: date)
    }
}
