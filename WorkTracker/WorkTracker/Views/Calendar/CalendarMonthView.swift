import SwiftUI

struct CalendarMonthView: View {
    @EnvironmentObject var store: DataStore
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDate: String?
    @Binding var selectedProjectId: String?
    @Binding var viewMode: MainViewMode

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: prevMonth) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text("\(String(year))年\(month)月")
                    .font(.title3.bold())
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            let days = generateDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(days, id: \.self) { day in
                    if day == 0 {
                        Color.clear.frame(height: 32)
                    } else {
                        let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
                        let hasLogs = !store.logsForDate(dateStr).isEmpty
                        Button(action: {
                            selectedDate = dateStr
                        }) {
                            Text("\(day)")
                                .font(.callout)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(hasLogs ? Color.accentColor.opacity(0.1) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)

            Divider().padding(.vertical, 8)

            GanttBarView(
                year: year, month: month,
                projects: store.projects,
                onProjectTap: { projectId in
                    selectedProjectId = projectId
                    viewMode = .projectDetail
                }
            )

            Spacer()

            if let date = selectedDate {
                Divider()
                DayDetailView(
                    date: date,
                    onBack: { selectedDate = nil },
                    onProjectTap: { projectId in
                        selectedProjectId = projectId
                        viewMode = .projectDetail
                    }
                )
            }
        }
    }

    private func generateDays() -> [Int] {
        let firstWeekday = DateHelpers.firstWeekdayOfMonth(year: year, month: month)
        let daysCount = DateHelpers.daysInMonth(year: year, month: month)
        var days: [Int] = Array(repeating: 0, count: firstWeekday - 1)
        days += Array(1...daysCount)
        return days
    }

    private func prevMonth() {
        if month == 1 { year -= 1; month = 12 } else { month -= 1 }
        selectedDate = nil
    }

    private func nextMonth() {
        if month == 12 { year += 1; month = 1 } else { month += 1 }
        selectedDate = nil
    }
}
