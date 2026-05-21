// swift-tools-version: 6.0

import PackageDescription

/// Currently, Firebase does not support dynamic libraries when installed via SPM, see https://github.com/firebase/firebase-ios-sdk/issues/8945 for details.
/// In order to use Firebase in both the app target and the `TangemAnalytics` module we need to use this thin dynamic shim library.
let package = Package(
    name: "TangemFirebaseDynamicShim",
    platforms: [
        .iOS("16.4"),
    ],
    products: [
        .library(
            name: "TangemFirebaseDynamicShim",
            type: .dynamic,
            targets: [
                "TangemFirebaseDynamicShim",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "12.12.0")),
    ],
    targets: [
        .target(
            name: "TangemFirebaseDynamicShim",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebasePerformance", package: "firebase-ios-sdk"),
            ],
            path: "TangemFirebaseDynamicShim"
        ),
    ]
)
