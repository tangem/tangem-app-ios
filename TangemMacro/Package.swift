// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "TangemMacro",
    platforms: [
        .iOS("16.4"),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "TangemMacro",
            targets: [
                "TangemMacro",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMajor(from: "602.0.0")),
    ],
    targets: [
        .target(
            name: "TangemMacro",
            dependencies: [
                "TangemMacroImplementation",
            ],
            path: "TangemMacro"
        ),
        .macro(
            name: "TangemMacroImplementation",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "TangemMacroImplementation"
        ),
    ]
)
