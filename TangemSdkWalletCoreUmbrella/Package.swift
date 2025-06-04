// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TangemSdkWalletCoreUmbrella",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TangemSdkWalletCoreUmbrella",
            targets: ["TangemSdkWalletCoreUmbrella"]),
    ],
    dependencies: [
        .package(url: "git@github.com:tangem-developments/tangem-sdk-ios.git", exact: "3.21.0"),
        .package(url: "git@github.com:tangem-developments/wallet-core-binaries-ios.git", exact: "4.1.20-tangem7"),
    ],
    targets: [
        .target(
            name: "TangemSdkWalletCoreUmbrella",
            dependencies: [
                .product(name: "TangemSdk", package: "tangem-sdk-ios"),
                .product(name: "TangemWalletCoreBinariesWrapper", package: "wallet-core-binaries-ios"),
            ]
        )
    ]
)
