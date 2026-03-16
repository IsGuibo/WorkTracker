import SwiftUI

struct CalendarMonthView: View {
    @EnvironmentObject var store: DataStore
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDate: String?
    @State private var popoverBarId: String?
    @State private var showWeeklyLog = false
    @State private var editingEntryId: String?
    @State private var editSummary: String = ""
    @State private var editManDays: String = ""
    @State private var hoveredEntryId: String?
    @State private var cachedGantt: [GanttProject] = []  // T6: 缓存，避免每次 body 重算
    var onProjectTap: (String) -> Void

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    private let gridSpacing: CGFloat = 1

    private var firstWeekday: Int {
        DateHelpers.firstWeekdayOfMonth(year: year, month: month)
    }

    private var daysInMonth: Int {
        DateHelpers.daysInMonth(year: year, month: month)
    }

    private var weeks: [[Int?]] {
        var result: [[Int?]] = []
        var current: [Int?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 1...daysInMonth {
            current.append(day)
            if current.count == 7 {
                result.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            while current.count < 7 { current.append(nil) }
            result.append(current)
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 月份导航
                monthHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                // 日历卡片
                calendarCard
                    .padding(.horizontal, 20)

                // 选中日期详情
                if let date = selectedDate {
                    dayDetailCard(date: date)
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.never)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.easeInOut(duration: 0.2), value: selectedDate)
        .onAppear { cachedGantt = ganttProjects() }
        .onChange(of: store.projects) { _, _ in cachedGantt = ganttProjects() }
        .onChange(of: year) { _, _ in cachedGantt = ganttProjects() }
        .onChange(of: month) { _, _ in cachedGantt = ganttProjects() }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(year) + "年")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(month)月")
                    .font(.system(.largeTitle, design: .rounded).bold())
            }

            Spacer()

            HStack(spacing: 4) {
                Button(action: { showWeeklyLog = true }) {
                    Label("记录工时", systemImage: "clock")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showWeeklyLog) {
                    WeeklyLogSheet()
                }

                Button(action: goToday) {
                    Text("今天")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button(action: prevMonth) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 28, height: 28)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .frame(width: 28, height: 28)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(spacing: 0) {
            // 星期标题行
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { idx, day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }

            Divider().opacity(0.5)

            // 日期网格
            let activeProjects = cachedGantt
            VStack(spacing: 0) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { weekIdx, week in
                    weekRow(week: week, activeProjects: activeProjects)
                    if weekIdx < weeks.count - 1 {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Week Row

    @ViewBuilder
    private func weekRow(week: [Int?], activeProjects: [GanttProject]) -> some View {
        VStack(spacing: 0) {
            // 日期数字行
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { col in
                    dateCell(day: week[col], col: col)
                }
            }

            // 甘特条
            let weekBars = barsForWeek(week: week, activeProjects: activeProjects)
            if !weekBars.isEmpty {
                GeometryReader { geo in
                    let colWidth = geo.size.width / 7.0
                    ZStack(alignment: .topLeading) {
                        ForEach(weekBars) { bar in
                            let x = colWidth * CGFloat(bar.startCol) + 3
                            let w = colWidth * CGFloat(bar.endCol - bar.startCol + 1) - 6
                            ganttBarView(bar: bar, width: max(w, 6))
                                .offset(x: x, y: CGFloat(bar.lane) * 8.0)
                        }
                    }
                }
                .frame(height: CGFloat(maxLane(weekBars) + 1) * 8.0 + 2)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Gantt Bar View

    private func ganttBarView(bar: WeekBar, width: CGFloat) -> some View {
        let barColor = ColorPalette.color(for: bar.projectId)
        let project = store.projects.first(where: { $0.id == bar.projectId })

        return RoundedRectangle(cornerRadius: 3)
            .fill(barColor.opacity(bar.isDone ? 0.25 : 0.6))
            .frame(width: width, height: 5)
            .help(bar.name + (bar.isDone ? " (已完成)" : ""))
            .popover(isPresented: Binding(
                get: { popoverBarId == bar.id },
                set: { if !$0 { popoverBarId = nil } }
            ), arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(barColor)
                            .frame(width: 8, height: 8)
                        Text(bar.name)
                            .font(.subheadline.weight(.semibold))
                    }

                    if let project = project {
                        HStack(spacing: 12) {
                            Label(project.status.label, systemImage: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(ColorPalette.statusColor(project.status))
                            if let due = project.dueDate {
                                Label(due, systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !project.currentStatus.isEmpty {
                            Text(project.currentStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Divider()

                    Button(action: {
                        popoverBarId = nil
                        onProjectTap(bar.projectId)
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("查看项目详情")
                        }
                        .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
                .padding(12)
                .frame(minWidth: 180)
            }
            .onTapGesture {
                popoverBarId = popoverBarId == bar.id ? nil : bar.id
            }
    }

    // MARK: - Date Cell

    @ViewBuilder
    private func dateCell(day: Int?, col: Int) -> some View {
        if let day = day {
            let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
            let logs = store.logsForDate(dateStr)
            let isToday = dateStr == DateHelpers.today()
            let isSelected = dateStr == selectedDate
            let isWeekend = col == 0 || col == 6

            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedDate = selectedDate == dateStr ? nil : dateStr
                }
            }) {
                VStack(spacing: 3) {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 30, height: 30)
                        } else if isToday {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 30, height: 30)
                        }

                        Text("\(day)")
                            .font(.system(.callout, design: .rounded).weight(
                                isToday || isSelected ? .bold : .regular
                            ))
                            .foregroundStyle(
                                isSelected ? .white :
                                isToday ? Color.accentColor :
                                isWeekend ? .secondary : .primary
                            )
                    }
                    .frame(height: 30)

                    // 日志指示点
                    HStack(spacing: 2) {
                        if !logs.isEmpty {
                            ForEach(0..<min(logs.count, 3), id: \.self) { i in
                                Circle()
                                    .fill(ColorPalette.color(for: logs[i].projectId).opacity(0.7))
                                    .frame(width: 4, height: 4)
                            }
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 46)
        }
    }

    // MARK: - Day Detail Card

    private func dayDetailCard(date: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(formatDateTitle(date))
                    .font(.headline)
                Spacer()
                Button(action: { selectedDate = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            let entries = store.logsForDate(date)
            if entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("暂无工作记录")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(entries) { entry in
                    // 展示模式
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ColorPalette.color(for: entry.projectId))
                            .frame(width: 3, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.projectName(for: entry.projectId))
                                .font(.subheadline.weight(.medium))
                            if !entry.summary.isEmpty {
                                Text(entry.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if let md = entry.manDays {
                            Text(String(format: "%.1f人天", md))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                        }

                        // 悬浮操作按钮
                        if hoveredEntryId == entry.id {
                            HStack(spacing: 2) {
                                Button(action: {
                                    editSummary = entry.summary
                                    editManDays = entry.manDays.map { String(format: "%.1f", $0) } ?? ""
                                    editingEntryId = entry.id
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.caption2)
                                        .frame(width: 22, height: 22)
                                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                                .help("编辑")

                                Button(action: {
                                    store.deleteLogEntry(date: date, entryId: entry.id)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.caption2)
                                        .foregroundStyle(.red.opacity(0.8))
                                        .frame(width: 22, height: 22)
                                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                                .help("删除")
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(hoveredEntryId == entry.id ? Color.primary.opacity(0.04) : Color.clear)
                    )
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredEntryId = isHovered ? entry.id : nil
                        }
                    }
                    .popover(isPresented: Binding(
                        get: { editingEntryId == entry.id },
                        set: { if !$0 { editingEntryId = nil } }
                    ), arrowEdge: .trailing) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("编辑记录")
                                .font(.subheadline.weight(.semibold))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("人天")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("0.0", text: $editManDays)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 120)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("备注")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("可选", text: $editSummary)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                            }

                            HStack {
                                Spacer()
                                Button("取消") {
                                    editingEntryId = nil
                                }
                                .keyboardShortcut(.escape, modifiers: [])
                                Button("保存") {
                                    saveEdit(date: date, entry: entry)
                                }
                                .keyboardShortcut(.return, modifiers: [])
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        .padding(14)
                        .frame(width: 240)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func formatDateTitle(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3 else { return dateStr }
        return "\(parts[1])月\(parts[2])日"
    }

    private func saveEdit(date: String, entry: LogEntry) {
        var updated = entry
        updated.summary = editSummary.trimmingCharacters(in: .whitespaces)
        updated.manDays = Double(editManDays)
        store.updateLogEntry(date: date, entry: updated)
        editingEntryId = nil
    }

    // MARK: - Gantt Data

    struct GanttProject {
        let id: String
        let name: String
        let isDone: Bool
        let segments: [(startDay: Int, endDay: Int)]  // 多段（暂停期为空白）
    }

    struct WeekBar: Identifiable {
        var id: String { "\(projectId)-\(startCol)-\(endCol)" }
        let projectId: String
        let name: String
        let isDone: Bool
        let startCol: Int
        let endCol: Int
        let lane: Int
    }

    private func ganttProjects() -> [GanttProject] {
        let monthStartStr = String(format: "%04d-%02d-01", year, month)
        let monthEndStr = String(format: "%04d-%02d-%02d", year, month, daysInMonth)
        let today = DateHelpers.today()

        var result: [GanttProject] = []
        for project in store.projects {
            guard !project.startDate.isEmpty else { continue }

            // 过滤掉 startDate 之前的历史记录，避免测试数据或噪音数据导致甘特条提前显示
            let history = project.statusHistory
                .filter { !$0.date.isEmpty && $0.date >= project.startDate }
                .sorted { $0.date < $1.date }
            var daySegments: [(Int, Int)] = []

            if history.isEmpty || project.status == .notStarted {
                // 未开始或无历史记录：整段显示到截止日期
                let projEnd: String
                if project.status == .done {
                    projEnd = project.completedDate ?? project.dueDate ?? today
                } else {
                    projEnd = project.dueDate ?? today
                }
                let cs = max(project.startDate, monthStartStr)
                let ce = min(projEnd, monthEndStr)
                if cs <= ce, let sd = dayOfMonth(cs), let ed = dayOfMonth(ce) {
                    daySegments.append((sd, ed))
                }
            } else {
                // 从 statusHistory 解析 inProgress 区间，暂停期留空白
                var isFirstInProgress = true
                for i in 0..<history.count {
                    let entry = history[i]
                    guard entry.status == .inProgress else { continue }

                    // 第一段 inProgress 以 project.startDate 为准（状态变更日期可能晚于实际开始）
                    let segStart = isFirstInProgress ? min(entry.date, project.startDate) : entry.date
                    isFirstInProgress = false
                    let segEnd: String
                    if i + 1 < history.count {
                        segEnd = history[i + 1].date
                    } else if project.status == .inProgress {
                        segEnd = max(project.dueDate ?? today, today)
                    } else if project.status == .done {
                        segEnd = project.completedDate ?? today
                    } else {
                        // 当前为暂停状态，这段 inProgress 没有后续记录（数据异常），跳过
                        continue
                    }

                    let cs = max(segStart, monthStartStr)
                    let ce = min(segEnd, monthEndStr)
                    guard cs <= ce else { continue }
                    if let sd = dayOfMonth(cs), let ed = dayOfMonth(ce) {
                        daySegments.append((sd, ed))
                    }
                }
            }

            guard !daySegments.isEmpty else { continue }
            result.append(GanttProject(
                id: project.id, name: project.name,
                isDone: project.status == .done,
                segments: daySegments
            ))
        }
        return result
    }

    private func barsForWeek(week: [Int?], activeProjects: [GanttProject]) -> [WeekBar] {
        let daysInWeek = week.compactMap { $0 }
        guard let weekStart = daysInWeek.first, let weekEnd = daysInWeek.last else { return [] }

        var bars: [WeekBar] = []
        var laneAssignment: [String: Int] = [:]
        var nextLane = 0

        for gp in activeProjects {
            // 收集该项目在本周有重叠的所有段
            let overlapping = gp.segments.compactMap { seg -> (startCol: Int, endCol: Int)? in
                let overlapStart = max(seg.startDay, weekStart)
                let overlapEnd = min(seg.endDay, weekEnd)
                guard overlapStart <= overlapEnd else { return nil }
                let startCol = week.firstIndex(where: { $0 == overlapStart }) ?? 0
                let endCol = week.firstIndex(where: { $0 == overlapEnd }) ?? 6
                return (startCol, endCol)
            }
            guard !overlapping.isEmpty else { continue }

            let lane: Int
            if let existing = laneAssignment[gp.id] {
                lane = existing
            } else {
                lane = nextLane
                laneAssignment[gp.id] = lane
                nextLane += 1
            }

            for seg in overlapping {
                bars.append(WeekBar(
                    projectId: gp.id, name: gp.name, isDone: gp.isDone,
                    startCol: seg.startCol, endCol: seg.endCol, lane: lane
                ))
            }
        }
        return bars
    }

    private func maxLane(_ bars: [WeekBar]) -> Int {
        bars.map(\.lane).max() ?? 0
    }

    private func dayOfMonth(_ dateStr: String) -> Int? {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3, let d = Int(parts[2]) else { return nil }
        return min(d, daysInMonth)
    }

    // MARK: - Navigation

    private func prevMonth() {
        if month == 1 { year -= 1; month = 12 } else { month -= 1 }
        selectedDate = nil
    }

    private func nextMonth() {
        if month == 12 { year += 1; month = 1 } else { month += 1 }
        selectedDate = nil
    }

    private func goToday() {
        year = Calendar.current.component(.year, from: Date())
        month = Calendar.current.component(.month, from: Date())
        selectedDate = DateHelpers.today()
    }
}
