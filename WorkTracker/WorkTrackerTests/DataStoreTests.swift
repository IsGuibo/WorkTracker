import XCTest
@testable import WorkTracker

final class DataStoreTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    @MainActor
    func testInitCreatesEmptyFiles() {
        let store = DataStore(directory: tempDir, enableFileWatcher: false)
        store.loadAll()
        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(
            atPath: tempDir.appendingPathComponent("projects.json").path))
        XCTAssertTrue(fm.fileExists(
            atPath: tempDir.appendingPathComponent("daily-logs.json").path))
        XCTAssertTrue(fm.fileExists(
            atPath: tempDir.appendingPathComponent("drafts").path))
    }

    @MainActor
    func testLoadProjects() throws {
        let json = """
        {"projects": [{"id": "p1", "name": "Test", "status": "in_progress",
        "priority": "high", "tags": [], "currentStatus": "doing",
        "startDate": "2026-03-10",
        "statusHistory": [{"status": "in_progress", "date": "2026-03-10"}],
        "description": "", "tasks": []}]}
        """.data(using: .utf8)!
        try json.write(to: tempDir.appendingPathComponent("projects.json"))
        let store = DataStore(directory: tempDir, enableFileWatcher: false)
        store.loadAll()
        XCTAssertEqual(store.projects.count, 1)
        XCTAssertEqual(store.projects[0].name, "Test")
    }

    @MainActor
    func testLoadInvalidJSONKeepsLastValid() throws {
        let valid = """
        {"projects": [{"id": "p1", "name": "Valid", "status": "done",
        "priority": "low", "tags": [], "currentStatus": "done",
        "startDate": "2026-01-01",
        "statusHistory": [{"status": "done", "date": "2026-01-01"}],
        "description": "", "tasks": []}]}
        """.data(using: .utf8)!
        try valid.write(to: tempDir.appendingPathComponent("projects.json"))
        let store = DataStore(directory: tempDir, enableFileWatcher: false)
        store.loadAll()
        XCTAssertEqual(store.projects.count, 1)

        try "{ broken".data(using: .utf8)!
            .write(to: tempDir.appendingPathComponent("projects.json"))
        store.loadAll()
        XCTAssertEqual(store.projects.count, 1)
        XCTAssertTrue(store.hasError)
    }

    @MainActor
    func testDraftReadWrite() async throws {
        let store = DataStore(directory: tempDir, enableFileWatcher: false)
        store.loadAll()
        store.saveDraft(projectId: "p1", content: "# Draft")
        // 等待后台写入完成
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(store.loadDraft(projectId: "p1"), "# Draft")
    }
}
