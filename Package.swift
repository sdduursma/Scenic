// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scenic",
    products: [
        .library(
            name: "Scenic",
            targets: ["Scenic"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble.git", from: "9.2.1"),
    ],
    targets: [
        .target(
            name: "Scenic",
            path: "Scenic"
        ),
        .testTarget(
            name: "ScenicTests",
            dependencies: ["Scenic"],
            path: "ScenicTests"
        )
    ]
)
