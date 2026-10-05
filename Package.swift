// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OneWord",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OneWord",
            targets: ["OneWord"]
        ),
        .executable(
            name: "OneWordApp",
            targets: ["OneWordApp"]
        )
    ],
    targets: [
        .target(
            name: "OneWord",
            dependencies: [],
            path: "OneWord/Sources/OneWord",
            exclude: ["Resources", "OneWordApp.swift"]
        ),
        .executableTarget(
            name: "OneWordApp",
            dependencies: ["OneWord"],
            path: "OneWord/Sources/OneWordApp"
        ),
        .testTarget(
            name: "OneWordTests",
            dependencies: ["OneWord"],
            path: "OneWord/Tests/OneWordTests"
        ),
    ]
)
