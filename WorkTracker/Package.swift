// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorkTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WorkTracker",
            path: "WorkTracker"
        ),
        .testTarget(
            name: "WorkTrackerTests",
            dependencies: ["WorkTracker"],
            path: "WorkTrackerTests"
        ),
    ]
)
