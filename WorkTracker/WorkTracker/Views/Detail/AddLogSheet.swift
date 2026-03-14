import SwiftUI

struct WeeklyLogSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var mondayDate: Date
    @State private var rows: [LogRow] = [LogRow()]

    private let dayLabels = ["一", "二", "三", "四", "五", "六", "日"]

    struct LogRow: Identifiable {
        let id = UUID()
        var projectId: String = ""
        var manDays: String = ""
        var remark: String = ""
        var selectedDays: Set<Int> = [0, 1, 2, 3, 4] // 默认周一~周五
    }

    init() {
        _mondayDate = State(initialValue: Self.mondayOfWeek(Date()))
    }

    private var totalManDays: Double {
        rows.compactMap { Double($0.manDays) }.reduce(0, +)
    }

    private var weekLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: mondayDate)!
        return "\(fmt.string(from: mondayDate)) ~ \(fmt.string(from: end))"
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider()
            weekSelector
            Divider()

            // 条目列表
            ScrollView {
                VStack(spacing: 10) {
                    ForEach($rows) { $row in
                        logRowCard(row: $row)
                    }

                    Button(action: { rows.append(LogRow()) }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("添加项目")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
            }
        }
        .frame(width: 540, height: 480)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            Button("取消") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            Spacer()
            Text("记录周工时")
                .font(.headline)
            Spacer()
            Button("保存") { save() }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .disabled(!canSave)
        }
        .padding()
    }

    // MARK: - Week Selector

    private var weekSelector: some View {
        HStack(spacing: 12) {
            Button(action: { shiftWeek(-7) }) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Text(weekLabel)
                .font(.subheadline.weight(.medium))
                .frame(width: 140)

            Button(action: { shiftWeek(7) }) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)

            Spacer()

            Text("合计 \(String(format: "%.1f", totalManDays)) 人天")
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Log Row Card

    private func logRowCard(row: Binding<LogRow>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("", selection: row.projectId) {
                    Text("选择项目").tag("")

                    let active = store.projects.filter { $0.status == .inProgress }
                    let others = store.projects.filter { $0.status != .inProgress }

                    if !active.isEmpty {
                        Section("进行中") {
                            ForEach(active) { p in
                                Text(p.name).tag(p.id)
                            }
                        }
                    }
                    if !others.isEmpty {
                        Section("其他") {
                            ForEach(others) { p in
                                Text(p.name).tag(p.id)
                            }
                        }
                    }
                }
                .frame(width: 160)

                TextField("人天", text: row.manDays)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)

                TextField("备注（可选）", text: row.remark)
                    .textFieldStyle(.roundedBorder)

                if rows.count > 1 {
                    Button(action: { rows.removeAll { $0.id == row.wrappedValue.id } }) {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 区间选择日历
            DayChipSelector(
                selectedDays: row.selectedDays,
                manDaysText: row.wrappedValue.manDays
            )
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Save

    private var canSave: Bool {
        rows.contains { !$0.projectId.isEmpty && !$0.selectedDays.isEmpty }
    }

    private func save() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        for row in rows {
            guard !row.projectId.isEmpty, !row.selectedDays.isEmpty else { continue }
            let total = Double(row.manDays) ?? 0
            let perDay = row.selectedDays.count > 0 ? total / Double(row.selectedDays.count) : 0
            let remark = row.remark.trimmingCharacters(in: .whitespaces)

            for dayIdx in row.selectedDays {
                let date = Calendar.current.date(byAdding: .day, value: dayIdx, to: mondayDate)!
                let dateStr = fmt.string(from: date)
                let entry = LogEntry(
                    projectId: row.projectId, taskId: nil,
                    summary: remark, manDays: perDay > 0 ? perDay : nil
                )
                store.addLogEntry(date: dateStr, entry: entry)
            }
        }
        dismiss()
    }

    // MARK: - Helpers

    private func shiftWeek(_ days: Int) {
        mondayDate = Calendar.current.date(byAdding: .day, value: days, to: mondayDate)!
    }

    static func mondayOfWeek(_ date: Date) -> Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let offset = weekday == 1 ? -6 : (2 - weekday)
        return cal.date(byAdding: .day, value: offset, to: date)!
    }
}

// MARK: - Day Chip Selector

struct DayChipSelector: View {
    @Binding var selectedDays: Set<Int>
    let manDaysText: String

    private let dayLabels = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { i in
                    let selected = selectedDays.contains(i)
                    let leftConnected = selected && selectedDays.contains(i - 1)
                    let rightConnected = selected && selectedDays.contains(i + 1)

                    let corners = chipCorners(left: leftConnected, right: rightConnected)

                    Text(dayLabels[i])
                        .font(.caption.weight(selected ? .semibold : .regular))
                        .frame(width: 34, height: 26)
                        .foregroundStyle(selected ? Color.accentColor : .secondary)
                        .background(
                            selected
                                ? Color.accentColor.opacity(0.12)
                                : Color.primary.opacity(0.03),
                            in: UnevenRoundedRectangle(
                                topLeadingRadius: corners.tl,
                                bottomLeadingRadius: corners.bl,
                                bottomTrailingRadius: corners.br,
                                topTrailingRadius: corners.tr
                            )
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                if selected {
                                    selectedDays.remove(i)
                                } else {
                                    selectedDays.insert(i)
                                }
                            }
                        }
                }
            }

            Spacer()

            let count = selectedDays.count
            if count > 0, let md = Double(manDaysText), md > 0 {
                Text("≈ 每天\(String(format: "%.2f", md / Double(count)))天")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize()
            }
        }
    }

    private struct CornerSet {
        let tl: CGFloat, tr: CGFloat, bl: CGFloat, br: CGFloat
    }

    private func chipCorners(left: Bool, right: Bool) -> CornerSet {
        let r: CGFloat = 6
        let s: CGFloat = 2
        return CornerSet(
            tl: left ? s : r,
            tr: right ? s : r,
            bl: left ? s : r,
            br: right ? s : r
        )
    }
}
