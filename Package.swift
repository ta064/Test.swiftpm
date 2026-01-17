// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "LinkedInAutoPost",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "LinkedInAutoPost",
            targets: ["LinkedInAutoPost"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LinkedInAutoPost",
            dependencies: [],
            path: "Sources"
        )
    ]
)
