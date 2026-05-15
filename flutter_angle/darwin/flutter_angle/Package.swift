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
            checksum: "f3faba16e527dd4dd9788e9378ed42916214761a74b9a84a5d14569842f678c3"
        ),
        .binaryTarget(
            name: "libGLESv2",
            url: "https://raw.githubusercontent.com/Knightro63/flutter_angle/refs/heads/main/libGLESv2.xcframework.zip",
            checksum: "9b107a172c1cbba9c7061bbc2b6a8e0c1d74754a91fa1dd92cba0227e972c659"
        ),
    ]
)