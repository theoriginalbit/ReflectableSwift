// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ReflectableSwift",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(name: "ReflectableSwift", targets: ["ReflectableSwift"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "ReflectableSwift", dependencies: []),
    ]
)
