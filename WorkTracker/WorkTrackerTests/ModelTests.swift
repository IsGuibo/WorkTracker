import XCTest
@testable import WorkTracker

final class ModelTests: XCTestCase {

    func testDecodeProject() throws {
        let json = """
        {
          "id": "p1", "name": "DP项目", "status": "in_progress",
          "priority": "high", "tags": ["定开"],
          "currentStatus": "等客户确认",
          "startDate": "2026-03-10",
          "statusHistory": [{"status": "in_progress", "date": "2026-03-10"}],
          "description": "DP定开项目", "tasks": []
        }
        """.data(using: .utf8)!
        let project = try JSONDecoder().decode(Project.self, from: json)
        XCTAssertEqual(project.id, "p1")
        XCTAssertEqual(project.status, .inProgress)
        XCTAssertEqual(project.priority, .high)
        XCTAssertEqual(project.statusHistory.count, 1)
        XCTAssertNil(project.dueDate)
    }

    func testDecodeProjectWithPauseHistory() throws {
        let json = """
        {
          "id": "p2", "name": "Test", "status": "paused",
          "priority": "low", "tags": [], "currentStatus": "暂停中",
          "startDate": "2026-03-01", "dueDate": "2026-04-01",
          "statusHistory": [
            {"status": "in_progress", "date": "2026-03-01"},
            {"status": "paused", "date": "2026-03-15"}
          ],
          "description": "",
          "tasks": [{"id": "t1", "name": "子任务1", "status": "done", "currentStatus": "完成"}]
        }
        """.data(using: .utf8)!
        let project = try JSONDecoder().decode(Project.self, from: json)
        XCTAssertEqual(project.statusHistory.count, 2)
        XCTAssertEqual(project.tasks.count, 1)
    }

    func testDecodeDailyLogs() throws {
        let json = """
        {
          "logs": [{
            "date": "2026-03-14",
            "entries": [{"projectId": "p1", "summary": "完成接口改造", "hoursSpent": 4}]
          }]
        }
        """.data(using: .utf8)!
        let container = try JSONDecoder().decode(DailyLogContainer.self, from: json)
        XCTAssertEqual(container.logs.count, 1)
        XCTAssertNil(container.logs[0].entries[0].taskId)
    }

    func testEncodeProject() throws {
        let project = Project(
            id: "p1", name: "Test", status: .inProgress, priority: .medium,
            tags: [], currentStatus: "进行中", startDate: "2026-03-10",
            dueDate: nil,
            statusHistory: [StatusChange(status: .inProgress, date: "2026-03-10")],
            description: "", tasks: []
        )
        let data = try JSONEncoder().encode(project)
        let str = String(data: data, encoding: .utf8)!
        XCTAssertTrue(str.contains("in_progress"))
    }

    func testProjectSortStatusUsesConfiguredOrderAndKeepsOriginalOrderWithinSameStatus() {
        let projects = [
            makeProject(id: "p1", name: "暂停项目", status: .paused, priority: .medium),
            makeProject(id: "p2", name: "进行中A", status: .inProgress, priority: .low),
            makeProject(id: "p3", name: "未开始项目", status: .notStarted, priority: .urgent),
            makeProject(id: "p4", name: "进行中B", status: .inProgress, priority: .high),
            makeProject(id: "p5", name: "完成项目", status: .done, priority: .medium)
        ]

        let sorted = ProjectSorter.sort(projects, by: .status)

        XCTAssertEqual(sorted.map(\.id), ["p2", "p4", "p3", "p1", "p5"])
    }

    func testProjectSortByPriorityOrdersFromUrgentToLow() {
        let projects = [
            makeProject(id: "p1", name: "中优先级", status: .notStarted, priority: .medium),
            makeProject(id: "p2", name: "紧急", status: .done, priority: .urgent),
            makeProject(id: "p3", name: "低优先级", status: .inProgress, priority: .low),
            makeProject(id: "p4", name: "高优先级", status: .paused, priority: .high)
        ]

        let sorted = ProjectSorter.sort(projects, by: .priority)

        XCTAssertEqual(sorted.map(\.id), ["p2", "p4", "p1", "p3"])
    }

    func testProjectSortByDueDatePlacesMissingDueDateLast() {
        let projects = [
            makeProject(id: "p1", name: "无截止", status: .inProgress, priority: .medium, dueDate: nil),
            makeProject(id: "p2", name: "月底截止", status: .inProgress, priority: .medium, dueDate: "2026-03-31"),
            makeProject(id: "p3", name: "月中截止", status: .inProgress, priority: .medium, dueDate: "2026-03-15")
        ]

        let sorted = ProjectSorter.sort(projects, by: .dueDate)

        XCTAssertEqual(sorted.map(\.id), ["p3", "p2", "p1"])
    }

    func testProjectSortByNameUsesLocalizedAscendingOrder() {
        let projects = [
            makeProject(id: "p1", name: "Zeta", status: .inProgress, priority: .medium),
            makeProject(id: "p2", name: "Alpha", status: .inProgress, priority: .medium),
            makeProject(id: "p3", name: "Beta", status: .inProgress, priority: .medium)
        ]

        let sorted = ProjectSorter.sort(projects, by: .name)

        XCTAssertEqual(sorted.map(\.id), ["p2", "p3", "p1"])
    }

    func testSidebarProjectQueryFiltersBeforeSorting() {
        let projects = [
            makeProject(id: "p1", name: "暂停低", status: .paused, priority: .low),
            makeProject(id: "p2", name: "进行中高", status: .inProgress, priority: .high),
            makeProject(id: "p3", name: "进行中低", status: .inProgress, priority: .low)
        ]

        let displayed = SidebarProjectQuery.projects(
            from: projects,
            statusFilter: .inProgress,
            priorityFilter: nil,
            sortOption: .name
        )

        XCTAssertEqual(displayed.map(\.id), ["p3", "p2"])
    }

    func testSidebarProjectQueryReportsNoActiveFiltersWhenBothFiltersAreEmpty() {
        XCTAssertFalse(
            SidebarProjectQuery.hasActiveFilters(
                statusFilter: nil,
                priorityFilter: nil
            )
        )
    }

    func testSidebarProjectQueryReportsActiveFiltersWhenAnyFilterIsSet() {
        XCTAssertTrue(
            SidebarProjectQuery.hasActiveFilters(
                statusFilter: .inProgress,
                priorityFilter: nil
            )
        )
        XCTAssertTrue(
            SidebarProjectQuery.hasActiveFilters(
                statusFilter: nil,
                priorityFilter: .high
            )
        )
    }

    func testSidebarToolbarPresentationUsesUnifiedIconButtons() {
        XCTAssertEqual(SidebarToolbarPresentation.sortButtonSystemImage, "arrow.up.arrow.down.circle")
        XCTAssertEqual(
            SidebarToolbarPresentation.filterButtonSystemImage(hasActiveFilters: false),
            "line.3.horizontal.decrease.circle"
        )
        XCTAssertEqual(
            SidebarToolbarPresentation.filterButtonSystemImage(hasActiveFilters: true),
            "line.3.horizontal.decrease.circle"
        )
    }

    func testSidebarToolbarPresentationHelpTextReflectsCurrentState() {
        XCTAssertEqual(
            SidebarToolbarPresentation.sortButtonHelp(sortOption: .status),
            "排序：状态"
        )
        XCTAssertEqual(
            SidebarToolbarPresentation.filterButtonHelp(
                statusFilter: nil,
                priorityFilter: nil
            ),
            "筛选"
        )
    }

    func testSidebarToolbarPresentationShowsActiveFilterConditionsInHelp() {
        XCTAssertEqual(
            SidebarToolbarPresentation.filterButtonHelp(
                statusFilter: .inProgress,
                priorityFilter: nil
            ),
            "筛选：状态=进行中"
        )
        XCTAssertEqual(
            SidebarToolbarPresentation.filterButtonHelp(
                statusFilter: nil,
                priorityFilter: .high
            ),
            "筛选：优先级=高"
        )
        XCTAssertEqual(
            SidebarToolbarPresentation.filterButtonHelp(
                statusFilter: .paused,
                priorityFilter: .urgent
            ),
            "筛选：状态=暂停，优先级=紧急"
        )
    }

    private func makeProject(
        id: String,
        name: String,
        status: ProjectStatus,
        priority: Priority,
        startDate: String = "2026-03-10",
        dueDate: String? = nil
    ) -> Project {
        Project(
            id: id,
            name: name,
            status: status,
            priority: priority,
            tags: [],
            currentStatus: status.label,
            startDate: startDate,
            dueDate: dueDate,
            statusHistory: [StatusChange(status: status, date: startDate)],
            description: "",
            tasks: []
        )
    }
}
