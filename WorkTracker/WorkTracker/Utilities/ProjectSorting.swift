import Foundation

enum ProjectSorter {
    static func sort(_ projects: [Project], by option: ProjectSortOption) -> [Project] {
        projects
            .enumerated()
            .sorted { lhs, rhs in
                let order = compare(lhs.element, rhs.element, by: option)
                if order == .orderedSame {
                    return lhs.offset < rhs.offset
                }
                return order == .orderedAscending
            }
            .map(\.element)
    }

    private static func compare(_ lhs: Project, _ rhs: Project, by option: ProjectSortOption)
        -> ComparisonResult
    {
        switch option {
        case .status:
            return compare(lhs.status.sidebarSortOrder, rhs.status.sidebarSortOrder)
        case .priority:
            return compare(lhs.priority.sidebarSortOrderDescending, rhs.priority.sidebarSortOrderDescending)
        case .startDate:
            return compare(lhs.startDate, rhs.startDate)
        case .dueDate:
            return compareDueDate(lhs.dueDate, rhs.dueDate)
        case .name:
            return lhs.name.localizedStandardCompare(rhs.name)
        }
    }

    private static func compare(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs < rhs {
            return .orderedAscending
        }
        if lhs > rhs {
            return .orderedDescending
        }
        return .orderedSame
    }

    private static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        if lhs < rhs {
            return .orderedAscending
        }
        if lhs > rhs {
            return .orderedDescending
        }
        return .orderedSame
    }

    private static func compareDueDate(_ lhs: String?, _ rhs: String?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (left?, right?):
            return compare(left, right)
        case (.some, .none):
            return .orderedAscending
        case (.none, .some):
            return .orderedDescending
        case (.none, .none):
            return .orderedSame
        }
    }
}

enum SidebarProjectQuery {
    static func projects(
        from projects: [Project],
        statusFilter: ProjectStatus?,
        priorityFilter: Priority?,
        sortOption: ProjectSortOption
    ) -> [Project] {
        let filtered = projects.filter { project in
            if let statusFilter, project.status != statusFilter {
                return false
            }
            if let priorityFilter, project.priority != priorityFilter {
                return false
            }
            return true
        }

        return ProjectSorter.sort(filtered, by: sortOption)
    }

    static func hasActiveFilters(statusFilter: ProjectStatus?, priorityFilter: Priority?) -> Bool {
        statusFilter != nil || priorityFilter != nil
    }
}

enum SidebarToolbarPresentation {
    static let sortButtonSystemImage = "arrow.up.arrow.down.circle"
    static let sortButtonTitle = "排序"
    static let filterButtonTitle = "筛选"

    static func filterButtonSystemImage(hasActiveFilters: Bool) -> String {
        "line.3.horizontal.decrease.circle"
    }

    static func sortButtonHelp(sortOption: ProjectSortOption) -> String {
        "排序：\(sortOption.label)"
    }

    static func filterButtonHelp(
        statusFilter: ProjectStatus?,
        priorityFilter: Priority?
    ) -> String {
        var parts: [String] = []

        if let statusFilter {
            parts.append("状态=\(statusFilter.label)")
        }
        if let priorityFilter {
            parts.append("优先级=\(priorityFilter.label)")
        }

        if parts.isEmpty {
            return "筛选"
        }
        return "筛选：\(parts.joined(separator: "，"))"
    }
}
