// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WorkTimeTracker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WorkTimeTracker", targets: ["WorkTimeTracker"])
    ],
    targets: [
        .executableTarget(
            name: "WorkTimeTracker",
            path: "WorkTimeTracker"
        ),
        .testTarget(
            name: "WorkTimeTrackerTests",
            dependencies: ["WorkTimeTracker"],
            path: "Tests/WorkTimeTrackerTests"
        )
    ]
)
