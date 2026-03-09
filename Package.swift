// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GitHubSearch",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GitHubSearch",
            targets: ["GitHubSearch"]
        ),
    ],
    targets: [
        .target(
            name: "GitHubSearch",
            path: "Sources",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "GitHubSearchTests",
            dependencies: ["GitHubSearch"],
            path: "Tests",
            exclude: ["UITests"]
        ),
        .testTarget(
            name: "GitHubSearchUITests",
            dependencies: ["GitHubSearch"],
            path: "Tests/UITests"
        ),
    ]
)
