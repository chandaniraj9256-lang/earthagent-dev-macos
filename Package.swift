// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "EarthAgent",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "EarthAgent", targets: ["EarthAgent"])
    ],
    targets: [
        .executableTarget(
            name: "EarthAgent",
            path: "Sources/EarthAgent"
        )
    ]
)
