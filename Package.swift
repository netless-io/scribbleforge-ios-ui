// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ScribbleForgeUI",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ScribbleForgeUI",
            targets: ["ScribbleForgeUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/netless-io/scribbleforge-ios-release.git", .upToNextMinor(from: "1.1.1"))
    ],
    targets: [
        .target(
            name: "ScribbleForgeUI",
            dependencies: [
                .product(name: "ScribbleForgeRTM", package: "scribbleforge-ios-release")
            ],
            path: "Sources",
            sources: ["ScribbleForgeUI"],
            resources: [
                .process("Resources")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
