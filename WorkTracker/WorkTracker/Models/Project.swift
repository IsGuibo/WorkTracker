import Foundation

struct StatusChange: Codable, Identifiable {
    var id: String { "\(status.rawValue)-\(date)" }
    let status: ProjectStatus
    let date: String
}

struct ProjectTask: Codable, Identifiable {
    let id: String
    var name: String
    var status: ProjectStatus
    var currentStatus: String
}

struct Project: Codable, Identifiable {
    let id: String
    var name: String
    var status: ProjectStatus
    var priority: Priority
    var tags: [String]
    var currentStatus: String
    var startDate: String
    var dueDate: String?
    var statusHistory: [StatusChange]
    var description: String
    var tasks: [ProjectTask]
}

struct ProjectContainer: Codable {
    var projects: [Project]
}
