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
}
