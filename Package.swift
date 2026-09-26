// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ThinkingOrbs",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8), .visionOS(.v1)],
    products: [
        .library(name: "ThinkingOrbs", targets: ["ThinkingOrbs"]),
    ],
    targets: [
        .target(name: "ThinkingOrbs"),
        .testTarget(
            name: "ThinkingOrbsTests",
            dependencies: ["ThinkingOrbs"],
            resources: [.copy("golden.json")]
        ),
    ]
)
