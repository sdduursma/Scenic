// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Scenic",
    products: [
        .library(
            name: "Scenic",
            targets: ["Scenic"]
        )
    ],
    targets: [
        .target(
            name: "Scenic",
            path: "Sources"
        ),
        .testTarget(
            name: "ScenicTests",
            dependencies: ["Scenic"],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
