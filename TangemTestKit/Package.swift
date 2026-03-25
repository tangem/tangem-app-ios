// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TangemTestKit",
    platforms: [.iOS("16.4"), .macOS(.v13)],
    products: [
        .library(name: "TangemTestKit", targets: ["TangemTestKit"]),
    ],
    targets: [
        .target(name: "TangemTestKit"),
    ]
)
