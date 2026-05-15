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
            dependencies: ["flutter_angle_binaries"],
            resources: [],
        ),
        .binaryTarget(
            name: "flutter_angle_binaries",
            url: "https://raw.githubusercontent.com/Knightro63/flutter_angle/refs/heads/main/flutter_angle_binaries.artifactbundle.zip",
            checksum: "8e2d3480b4760babca355ebb10eb3ec0ea8d537c2bfd2bff268cbccbf6261bfd"
        ),
    ]
)