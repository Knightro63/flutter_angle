// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_angle",
    platforms: [
        .macOS("10.14"),
        .iOS("12.0")
    ],
    products: [
        .library(name: "flutter-angle", targets: ["flutter_angle"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_angle",
            dependencies: ["libEGL", "libGLESv2"],
            resources: [],
        ),
        .binaryTarget(
            name: "libEGL",
            url: "https://raw.githubusercontent.com/Knightro63/flutter_angle/refs/heads/main/libEGL.xcframework.zip",
            checksum: "d02766406d39daae169465c235b3f98a3d036799d3f5155ec51b0a4437d18dae"
        ),
        .binaryTarget(
            name: "libGLESv2",
            url: "https://raw.githubusercontent.com/Knightro63/flutter_angle/refs/heads/main/libGLESv2.xcframework.zip",
            checksum: "bc0b761a1e6797b2d5dced822cc76d4c119cd7f1bf342c6552d95418df730391"
        ),
    ]
)