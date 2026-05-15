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
            checksum: "d52a155796377991926da0973abbe20e5642e6aab4f40651edb84b76c7690c5c"
        ),
        .binaryTarget(
            name: "libGLESv2",
            url: "https://raw.githubusercontent.com/Knightro63/flutter_angle/refs/heads/main/libGLESv2.xcframework.zip",
            checksum: "36a04458baecbbc78c85c6ada6e0dacb38002017ac807e8b71880c74200b7f9c"
        ),
    ]
)