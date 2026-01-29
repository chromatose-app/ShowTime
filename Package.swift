// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShowTime",
    products: [.library(name: "ShowTime", targets: ["ShowTime"])],
    targets: [.target(name: "ShowTime"), .testTarget(name: "ShowTimeTests", dependencies: ["ShowTime"])],
    swiftLanguageModes: [.v5]
)
