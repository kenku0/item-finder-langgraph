// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DoomscrollGPT",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DoomscrollGPT",
            targets: ["DoomscrollGPT"]
        )
    ],
    dependencies: [
        // No external dependencies - using native iOS frameworks
    ],
    targets: [
        .target(
            name: "DoomscrollGPT",
            dependencies: [],
            path: "DoomscrollGPT"
        ),
        .testTarget(
            name: "DoomscrollGPTTests",
            dependencies: ["DoomscrollGPT"],
            path: "DoomscrollGPTTests"
        )
    ]
)