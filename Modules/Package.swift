// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

// MARK: - Package

let package = Package(
    name: modulesWrapperLibraryName,
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: modulesWrapperLibraryName,
            targets: [
                modulesWrapperLibraryName,
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.2")),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "8.3.2")),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", .upToNextMajor(from: "0.6.7")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.19")),
        .package(url: "https://github.com/airbnb/lottie-spm.git", .upToNextMajor(from: "4.5.2")),
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", .upToNextMajor(from: "1.8.1")),
        .package(url: "git@github.com:tangem-developments/tangem-sdk-ios.git", .upToNextMajor(from: "3.21.1")),
    ],
    targets: [modulesWrapperLibrary] + serviceModules + featureModules + unitTestsModules
)

// MARK: - Service Modules

/// Valid examples are `CommonUI`, `Utils`, `NetworkLayer`, `ModelData`, etc.
var serviceModules: [PackageDescription.Target] {
    [
        .tangemTarget(
            name: "TangemAccessibilityIdentifiers",
            dependencies: []
        ),
        .tangemTarget(
            name: "TangemAssets",
            dependencies: [
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            exclude: ["Templates"],
            resources: [
                .process("Assets"),
                .process("LottieAnimations"),
            ]
        ),
        .tangemTarget(
            name: "TangemLocalization",
            exclude: ["Templates"],
            resources: [.process("Localizations")]
        ),
        .tangemTarget(
            name: "TangemFoundation",
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemLogger",
            dependencies: [
                "ZIPFoundation",
                "TangemFoundation",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemNetworkUtils",
            dependencies: [
                "Moya",
                "Alamofire",
                "TangemFoundation",
                "TangemLogger",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemUIUtils",
            dependencies: [
                "Kingfisher",
                "TangemAssets",
                "TangemLocalization",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemUI",
            dependencies: [
                "TangemAssets",
                "TangemFoundation",
                "TangemUIUtils",
                "TangemLocalization",
                "TangemAccessibilityIdentifiers",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemHotSdk",
            path: "TangemHotSdk/Sources",
            dependencies: [
                .product(name: "TangemSdk", package: "tangem-sdk-ios"),
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
}

// MARK: - Feature Modules

/// Valid examples are `Onboarding`, `Auth`, `Catalog`, etc.
var featureModules: [PackageDescription.Target] {
    [
        .tangemTarget(
            name: "TangemStories",
            dependencies: [
                "Kingfisher",
                "TangemLocalization",
                "TangemUI",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemNFT",
            dependencies: [
                "Moya",
                "AnyCodable",
                "CombineExt",
                "TangemAssets",
                "TangemUI",
                "TangemUIUtils",
                "TangemFoundation",
                "TangemLocalization",
                "TangemLogger",
                "TangemNetworkUtils",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
}

// MARK: - Unit Test Modules

var unitTestsModules: [PackageDescription.Target] {
    [
        .tangemTestTarget(
            name: "TangemFoundationTests",
            dependencies: [
                "TangemFoundation",
            ]
        ),
        .tangemTestTarget(
            name: "TangemNFTTests",
            dependencies: [
                "TangemNFT",
            ]
        ),
        .tangemTestTarget(
            name: "TangemLoggerTests",
            dependencies: [
                "TangemLogger",
            ]
        ),
        .tangemTestTarget(
            name: "TangemHotSdkTests",
            path: "TangemHotSdk/Tests",
            dependencies: [
                "TangemFoundation",
                "TangemHotSdk",
            ]
        ),
    ]
}

// MARK: - Wrapper Library (implementation details, do not edit)

var modulesWrapperLibraryName: String { "TangemModules" }

var modulesWrapperLibrary: PackageDescription.Target {
    .tangemTarget(
        name: modulesWrapperLibraryName,
        dependencies: serviceModules.asDependencies() + featureModules.asDependencies()
    )
}

// MARK: - Private implementation

private extension PackageDescription.Target {
    /// Just a dumb wrapper that sets the module `path` to the value of the module `name`.
    static func tangemTarget(
        name: String,
        path: String? = nil,
        dependencies: [PackageDescription.Target.Dependency] = [],
        exclude: [String] = [],
        sources: [String]? = nil,
        resources: [PackageDescription.Resource]? = nil,
        publicHeadersPath: String? = nil,
        packageAccess: Bool = true,
        cSettings: [PackageDescription.CSetting]? = nil,
        cxxSettings: [PackageDescription.CXXSetting]? = nil,
        swiftSettings: [PackageDescription.SwiftSetting]? = nil,
        linkerSettings: [PackageDescription.LinkerSetting]? = nil,
        plugins: [PackageDescription.Target.PluginUsage]? = nil
    ) -> PackageDescription.Target {
        let path = path ?? name
        let enrichedCSettings: [PackageDescription.CSetting]?
        let enrichedCXXSettings: [PackageDescription.CXXSetting]?
        let enrichedSwiftSettings: [PackageDescription.SwiftSetting]?

        if let buildSettings = makeBuildSettings() {
            enrichedCSettings = (cSettings ?? []) + buildSettings.cSettings
            enrichedCXXSettings = (cxxSettings ?? []) + buildSettings.cxxSettings
            enrichedSwiftSettings = (swiftSettings ?? []) + buildSettings.swiftSettings
        } else {
            enrichedCSettings = cSettings
            enrichedCXXSettings = cxxSettings
            enrichedSwiftSettings = swiftSettings
        }

        return target(
            name: name,
            dependencies: dependencies,
            path: path,
            exclude: exclude,
            sources: sources,
            resources: resources,
            publicHeadersPath: publicHeadersPath,
            packageAccess: packageAccess,
            cSettings: enrichedCSettings,
            cxxSettings: enrichedCXXSettings,
            swiftSettings: enrichedSwiftSettings,
            linkerSettings: linkerSettings,
            plugins: plugins
        )
    }

    /// Just a dumb wrapper that sets the module `path` to the value of the module `name`.
    static func tangemTestTarget(
        name: String,
        path: String? = nil,
        dependencies: [PackageDescription.Target.Dependency] = [],
        exclude: [String] = [],
        sources: [String]? = nil,
        resources: [PackageDescription.Resource]? = nil,
        packageAccess: Bool = true,
        cSettings: [PackageDescription.CSetting]? = nil,
        cxxSettings: [PackageDescription.CXXSetting]? = nil,
        swiftSettings: [PackageDescription.SwiftSetting]? = nil,
        linkerSettings: [PackageDescription.LinkerSetting]? = nil,
        plugins: [PackageDescription.Target.PluginUsage]? = nil
    ) -> PackageDescription.Target {
        let path = path ?? name
        let enrichedCSettings: [PackageDescription.CSetting]?
        let enrichedCXXSettings: [PackageDescription.CXXSetting]?
        let enrichedSwiftSettings: [PackageDescription.SwiftSetting]?

        if let buildSettings = makeBuildSettings() {
            enrichedCSettings = (cSettings ?? []) + buildSettings.cSettings
            enrichedCXXSettings = (cxxSettings ?? []) + buildSettings.cxxSettings
            enrichedSwiftSettings = (swiftSettings ?? []) + buildSettings.swiftSettings
        } else {
            enrichedCSettings = cSettings
            enrichedCXXSettings = cxxSettings
            enrichedSwiftSettings = swiftSettings
        }

        return testTarget(
            name: name,
            dependencies: dependencies,
            path: path,
            exclude: exclude,
            sources: sources,
            resources: resources,
            packageAccess: packageAccess,
            cSettings: enrichedCSettings,
            cxxSettings: enrichedCXXSettings,
            swiftSettings: enrichedSwiftSettings,
            linkerSettings: linkerSettings,
            plugins: plugins
        )
    }
}

private extension Array where Element == PackageDescription.Target {
    func asDependencies() -> [PackageDescription.Target.Dependency] {
        return map { .target(name: $0.name) }
    }
}

// MARK: - Conditional complication flags

private struct BuildSettings {
    var cSettings: [PackageDescription.CSetting]
    var cxxSettings: [PackageDescription.CXXSetting]
    var swiftSettings: [PackageDescription.SwiftSetting]
}

/// Loosely based on this thread: https://forums.swift.org/t/43593
/// - Warning: Does not work with Xcode, only works for builds made with the `fastlane`, `xcodebuild` or `swift build`.
private func makeBuildSettings() -> BuildSettings? {
    func makeAlphaBetaBuildSettings() -> BuildSettings {
        return BuildSettings(
            cSettings: [.define("ALPHA_OR_BETA", to: "1")],
            cxxSettings: [.define("ALPHA_OR_BETA", to: "1")],
            swiftSettings: [.define("ALPHA_OR_BETA")]
        )
    }

    if ProcessInfo.processInfo.environment["SWIFT_PACKAGE_BUILD_FOR_ALPHA"] != nil {
        var buildSettings = makeAlphaBetaBuildSettings()
        buildSettings.cSettings.append(.define("ALPHA", to: "1"))
        buildSettings.cxxSettings.append(.define("ALPHA", to: "1"))
        buildSettings.swiftSettings.append(.define("ALPHA"))
        return buildSettings
    }

    if ProcessInfo.processInfo.environment["SWIFT_PACKAGE_BUILD_FOR_BETA"] != nil {
        var buildSettings = makeAlphaBetaBuildSettings()
        buildSettings.cSettings.append(.define("BETA", to: "1"))
        buildSettings.cxxSettings.append(.define("BETA", to: "1"))
        buildSettings.swiftSettings.append(.define("BETA"))
        return buildSettings
    }

    return nil
}
