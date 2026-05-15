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
            url: "https://raw.githubusercontent.com/Knightro63/flutter_angle/refs/heads/main/libEGL.xcframework.tar.gz",
            checksum: "7f23910d24a49e74e9696e4d2320951450d2524e1263b492ec83c48264370b2f"
        ),
        .binaryTarget(
            name: "libGLESv2",
            url: "https://raw.githubusercontent.com/Knightro63/flutter_angle/refs/heads/main/libGLESv2.xcframework.tar.gz",
            checksum: "e617ef1dc15d6b36f0c0f9ff2b29d61ad37b7298eb7c8906783e4a70fb19cd56"
        ),
    ]
)