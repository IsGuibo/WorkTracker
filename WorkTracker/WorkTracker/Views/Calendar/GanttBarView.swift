import SwiftUI

struct GanttBarView: View {
    let year: Int
    let month: Int
    let firstWeekday: Int
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
        projects.filter { !segments(for: $0).isEmpty }
    }

    /// Total rows in the calendar grid
    private var totalRows: Int {
        let totalCells = (firstWeekday - 1) + daysInMonth
        return (totalCells + 6) / 7
    }

    /// Convert day-of-month (1-based) to grid column (0-based)
    private func column(for day: Int) -> Int {
        (firstWeekday - 1 + day - 1) % 7
    }

    /// Convert day-of-month (1-based) to grid row (0-based)
    private func row(for day: Int) -> Int {
        (firstWeekday - 1 + day - 1) / 7
    }

    var body: some View {
        if visibleProjects.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(visibleProjects) { project in
                    ganttRow(for: project)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func ganttRow(for project: Project) -> some View {
        GeometryReader { geo in
            let colWidth = geo.size.width / 7.0
            let segs = segments(for: project)
            ZStack(alignment: .topLeading) {
                ForEach(segs, id: \.startDay) { seg in
                    // Split segment into per-row pieces
                    let pieces = splitIntoRows(seg)
                    ForEach(pieces, id: \.row) { piece in
                        let x = colWidth * CGFloat(piece.startCol)
                        let w = colWidth * CGFloat(piece.endCol - piece.startCol + 1)
                        let y = CGFloat(piece.row) * 22.0
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ColorPalette.color(for: project.id)
                                .opacity(project.status == .done ? 0.4 : 0.8))
                            .frame(width: max(w, 4), height: 18)
                            .overlay(alignment: .leading) {
                                if w > 50 && piece == pieces.first {
                                    Text(project.name)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .padding(.leading, 4)
                                }
                            }
                            .offset(x: x, y: y)
                    }
                }
            }
        }
        .frame(height: CGFloat(totalRows) * 22.0)
        .contentShape(Rectangle())
        .onTapGesture { onProjectTap(project.id) }
    }

    struct RowPiece: Equatable {
        let row: Int
        let startCol: Int
        let endCol: Int
    }

    /// Split a segment spanning multiple rows into per-row pieces
    private func splitIntoRows(_ seg: Segment) -> [RowPiece] {
        var pieces: [RowPiece] = []
        let startRow = row(for: seg.startDay)
        let endRow = row(for: seg.endDay)

        for r in startRow...endRow {
            let sc = (r == startRow) ? column(for: seg.startDay) : 0
            let ec = (r == endRow) ? column(for: seg.endDay) : 6
            pieces.append(RowPiece(row: r, startCol: sc, endCol: ec))
        }
        return pieces
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
