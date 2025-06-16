// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_angle_darwin",
    platforms: [
        .macOS("10.14"),
        .iOS("12.0")
    ],
    products: [
        .library(name: "flutter-angle-darwin", targets: ["flutter_angle_darwin"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_angle_darwin",
            dependencies: ["libEGL","libGLESv2"],
            resources: []
        ),
        .binaryTarget(
            name: "libEGL",
            path: "./Frameworks/libEGL.xcframework"
        ),
        .binaryTarget(
            name: "libGLESv2",
            path: "./Frameworks/libGLESv2.xcframework"
        ),
    ]
)
