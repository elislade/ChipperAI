// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChipperAI",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "ChipperAI", targets: ["ChipperAI"]),
    ],
    targets: [
        .target(name: "ChipperAI", dependencies: []),
        .testTarget(name: "ChipperAITests", dependencies: ["ChipperAI"]),
    ]
)
