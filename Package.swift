// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ShowTime",
    platforms: [.iOS(.v14)],
    products: [.library(name: "ShowTime", targets: ["ShowTime"])],
    targets: [
        .target(name: "ShowTime"),
        .testTarget(name: "ShowTimeTests", dependencies: ["ShowTime"]),
    ]
)
