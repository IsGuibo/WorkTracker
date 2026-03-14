import SwiftUI

struct GanttBarView: View {
    let year: Int
    let month: Int
    let projects: [Project]
    let onProjectTap: (String) -> Void

    private var daysInMonth: Int {
        DateHelpers.daysInMonth(year: year, month: month)
    }

    private var monthStart: String {
        String(format: "%04d-%02d-01", year, month)
    }

    private var monthEnd: String {
        String(format: "%04d-%02d-%02d", year, month, daysInMonth)
    }

    private var visibleProjects: [Project] {
        projects.filter { project in
            !segments(for: project).isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if visibleProjects.isEmpty {
                Text("当月无项目时间线")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(visibleProjects) { project in
                    ganttRow(for: project)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func ganttRow(for project: Project) -> some View {
        GeometryReader { geo in
            let dayWidth = geo.size.width / CGFloat(daysInMonth)
            ZStack(alignment: .leading) {
                ForEach(segments(for: project), id: \.startDay) { seg in
                    let x = dayWidth * CGFloat(seg.startDay - 1)
                    let w = dayWidth * CGFloat(seg.endDay - seg.startDay + 1)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ColorPalette.color(for: project.id)
                            .opacity(project.status == .done ? 0.4 : 0.8))
                        .frame(width: max(w, 4), height: 18)
                        .offset(x: x)
                        .overlay(alignment: .leading) {
                            if w > 50 {
                                Text(project.name)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .padding(.leading, 4)
                                    .offset(x: x)
                            }
                        }
                }
            }
        }
        .frame(height: 22)
        .contentShape(Rectangle())
        .onTapGesture { onProjectTap(project.id) }
    }

    struct Segment {
        let startDay: Int
        let endDay: Int
    }

    private func segments(for project: Project) -> [Segment] {
        let history = project.statusHistory.sorted { $0.date < $1.date }
        guard !history.isEmpty else { return [] }

        var result: [Segment] = []
        let today = DateHelpers.today()

        for i in 0..<history.count {
            let entry = history[i]
            guard entry.status == .inProgress else { continue }

            let segStart = entry.date
            let segEnd: String
            if i + 1 < history.count {
                segEnd = history[i + 1].date
            } else if project.status == .inProgress {
                segEnd = project.dueDate ?? today
            } else {
                segEnd = entry.date
            }

            let clampedStart = max(segStart, monthStart)
            let clampedEnd = min(segEnd, monthEnd)
            guard clampedStart <= clampedEnd else { continue }

            if let startDay = dayOfMonth(clampedStart),
               let endDay = dayOfMonth(clampedEnd) {
                result.append(Segment(startDay: startDay, endDay: endDay))
            }
        }
        return result
    }

    private func dayOfMonth(_ dateStr: String) -> Int? {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3, let d = Int(parts[2]) else { return nil }
        return min(d, daysInMonth)
    }
}
