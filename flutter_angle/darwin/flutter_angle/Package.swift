// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_angle",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12)
    ],
    products: [
        .library(name: "flutter-angle", targets: ["flutter_angle"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_angle",
            dependencies: [
                "libEGL",
                "libGLESv2",
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
        ),
        .binaryTarget(
            name: "libEGL",
            url: "https://raw.githubusercontent.com/Knightro63/FlutterAngle/master/SPM/libEGL.xcframework.zip",
            checksum: "7303b05113ac770853c954cfcb200dcb208b6d80bdbbac7c78676e283ebc3ebc"
        ),
        .binaryTarget(
            name: "libGLESv2",
            url: "https://raw.githubusercontent.com/Knightro63/FlutterAngle/master/SPM/libGLESv2.xcframework.zip",
            checksum: "ad61f1a7ef30f081b6f0ed025e5379d111ca0f89e7de020612881dc069a9c266"
        ),
    ]
)
