// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

// MARK: - Package

let package = Package(
    name: modulesWrapperLibraryName,
    defaultLocalization: "en",
    platforms: [
        .iOS("16.4"),
    ],
    products: [
        .library(
            name: modulesWrapperLibraryName,
            targets: [
                modulesWrapperLibraryName,
            ]
        ),
        .library(
            name: "BlockchainSdk",
            targets: [
                "BlockchainSdk",
            ]
        ),
    ],
    dependencies: [
        .package(path: "../vendor/ios_dependencies/checkouts/Moya"),
        .package(path: "../vendor/ios_dependencies/checkouts/Alamofire"),
        .package(path: "../vendor/ios_dependencies/checkouts/Kingfisher"),
        .package(path: "../vendor/ios_dependencies/checkouts/AnyCodable"),
        .package(path: "../vendor/ios_dependencies/checkouts/ZIPFoundation"),
        .package(path: "../vendor/ios_dependencies/checkouts/lottie-spm"),
        .package(path: "../vendor/ios_dependencies/checkouts/CombineExt"),
        .package(path: "../vendor/ios_dependencies/checkouts/tangem-sdk-ios"),
        .package(path: "../vendor/ios_dependencies/checkouts/CryptoSwift"),
        // When a Swift macro target (`TangemMacro`) is used in the same package (`TangemModules`) in which it is defined,
        // and that package contains a test target (`BlockchainSdkTests`) that uses macros from that macro target,
        // this causes linker to incorrectly link the macros target plugin (build for macOS) into the iOS test binary,
        // even if it is not explicitly specified as a dependency.
        // The workaround for this issue is to place the Swift macros target (`TangemMacro`) in a separate local package (`TangemMacro`).
        .package(path: "../TangemMacro"),
        .package(path: "../TangemFirebaseDynamicShim"),
        .package(path: "../vendor/ios_dependencies/checkouts/IdensicMobileSDK-iOS"),
        .package(path: "../vendor/ios_dependencies/checkouts/BlurUIKit"),
        // BSDK only dependencies:
        // AnyCodable
        .package(path: "../vendor/ios_dependencies/checkouts/SwiftBinanceChain"),
        .package(path: "../vendor/ios_dependencies/checkouts/swift-sodium"),
        .package(path: "../vendor/ios_dependencies/checkouts/bdk-swift"),
        // CombineExt
        // CryptoSwift
        .package(path: "../vendor/ios_dependencies/checkouts/grpc-swift"),
        .package(path: "../vendor/ios_dependencies/checkouts/hiero-sdk-swift"),
        .package(path: "../vendor/ios_dependencies/checkouts/IcpKit"),
        // Moya
        .package(path: "../vendor/ios_dependencies/checkouts/PotentCodables"),
        .package(path: "../vendor/ios_dependencies/checkouts/ScaleCodec.swift"),
        .package(path: "../vendor/ios_dependencies/checkouts/secp256k1.swift"),
        .package(path: "../vendor/ios_dependencies/checkouts/Solana.Swift"),
        .package(path: "../vendor/ios_dependencies/checkouts/stellar-ios-mac-sdk"),
        .package(path: "../vendor/ios_dependencies/checkouts/SwiftCBOR"),
        .package(path: "../vendor/ios_dependencies/checkouts/swift-protobuf-binaries"),
        // TangemModules
        // TangemSDK
        .package(path: "../vendor/ios_dependencies/checkouts/wallet-core-binaries-ios"),
        .package(path: "../vendor/ios_dependencies/checkouts/ton-swift"),
        .package(path: "../vendor/ios_dependencies/checkouts/BigInt"),
        .package(path: "../vendor/ios_dependencies/checkouts/swift-collections"),
    ],
    targets: [modulesWrapperLibrary] + serviceModules + featureModules + unitTestsModules
)

// MARK: - Service Modules

/// Valid examples are `CommonUI`, `Utils`, `NetworkLayer`, `ModelData`, etc.
var serviceModules: [PackageDescription.Target] {
    [
        .tangemTarget(
            name: "BlockchainSdk",
            dependencies: [
                // BSDK external (not from the `TangemModules` package) dependencies:
                "AnyCodable",
                "BigInt",
                .product(name: "BinanceChain", package: "SwiftBinanceChain"),
                .product(name: "BitcoinDevKit", package: "bdk-swift"),
                "CombineExt",
                "CryptoSwift",
                .product(name: "GRPC", package: "grpc-swift"), // Not used directly, a transitive dependency of `hiero-sdk-swift`
                .product(name: "Hiero", package: "hiero-sdk-swift"),
                "IcpKit",
                "Moya",
                .product(name: "OrderedCollections", package: "swift-collections"),
                "PotentCodables", // For `PotentCBOR` only
                .product(name: "ScaleCodec", package: "ScaleCodec.swift"),
                .product(name: "secp256k1", package: "secp256k1.swift"),
                .product(name: "Sodium", package: "swift-sodium"),
                .product(name: "SolanaSwift", package: "Solana.Swift"),
                .product(name: "stellarsdk", package: "stellar-ios-mac-sdk"),
                "SwiftCBOR",
                .product(name: "SwiftProtobuf", package: "swift-protobuf-binaries"),
                .product(name: "TangemMacro", package: "TangemMacro"),
                .product(name: "TangemSdk", package: "tangem-sdk-ios"),
                .product(name: "TangemWalletCoreBinariesWrapper", package: "wallet-core-binaries-ios"),
                .product(name: "TonSwift", package: "ton-swift"),
                // BSDK (from the `TangemModules` package) dependencies:
                // Use the following command in the terminal from the root of the repo to find all internal dependencies:
                // find ./Modules/BlockchainSdk -iname "*.swift" -type f -exec grep -rF "import Tangem" {} \; | cut -d ':' -f2 | sort | uniq
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
        .tangemTarget(
            name: "TangemAccessibilityIdentifiers"
        ),
        .tangemTarget(
            name: "TangemAnalytics",
            dependencies: [
                .product(name: "TangemFirebaseDynamicShim", package: "TangemFirebaseDynamicShim"),
                "TangemFoundation",
                "TangemLogger",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
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
            name: "TangemFoundation",
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemLocalization",
            exclude: ["Templates"],
            resources: [.process("Localizations")]
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
            name: "TangemMobileWalletSdk",
            path: "TangemMobileWalletSdk/Sources/swift",
            dependencies: [
                .product(name: "TangemSdk", package: "tangem-sdk-ios"),
                .target(name: "TrezorCrypto"),
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
            name: "TangemUI",
            dependencies: [
                "CombineExt",
                "TangemAssets",
                "TangemFoundation",
                "TangemUIUtils",
                "TangemLocalization",
                "TangemAccessibilityIdentifiers",
                "TangemLogger",
                .product(name: "BlurSwiftUI", package: "BlurUIKit"),
                .product(name: "TangemMacro", package: "TangemMacro"),
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
                "TangemFoundation",
                "TangemUIUtilsObjC",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemUIUtilsObjC"
        ),
        // `TrezorCrypto` library is from WalletCore repo, commit 6e9567b5f9efc965e4fc1af00ecf485c4bf040a1
        .tangemTarget(
            name: "TrezorCrypto",
            path: "TangemMobileWalletSdk/Sources/TrezorCrypto",
            exclude: [
                "crypto/ed25519-donna/README.md",
                "crypto/nist256p1.table",
                "crypto/secp256k1.table",
            ],
            sources: ["crypto"],
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-Wno-shorten-64-to-32"]),
            ],
        ),
    ]
}

// MARK: - Feature Modules

/// Valid examples are `Onboarding`, `Auth`, `Catalog`, etc.
var featureModules: [PackageDescription.Target] {
    [
        .tangemTarget(
            name: "TangemAccounts",
            dependencies: [
                "TangemAssets",
                "TangemLocalization",
                "TangemUIUtils",
                "TangemUI",
                "TangemFoundation",
                "TangemAccessibilityIdentifiers",
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
                "TangemAccounts",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemPay",
            dependencies: [
                .product(name: "TangemSdk", package: "tangem-sdk-ios"),
                .product(name: "IdensicMobileSDK", package: "idensicmobilesdk-ios"),
                "BlockchainSdk",
                "CryptoSwift",
                "TangemAssets",
                "TangemFoundation",
                "TangemNetworkUtils",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemStories",
            dependencies: [
                "Kingfisher",
                "TangemLocalization",
                "TangemUI",
                "TangemFoundation",
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
            name: "BlockchainSdkTests",
            dependencies: [
                // Use the following command in the terminal from the root of the repo to find all dependencies that are imported in the tests:
                // find ./Modules/BlockchainSdkTests -iname "*.swift" -type f -exec grep -rF "import " {} \; | cut -d ':' -f2 | sort | uniq
                "BlockchainSdk",
                "TangemFoundation",
                "TangemNetworkUtils",
                .product(name: "TangemSdk", package: "tangem-sdk-ios"),
                "BigInt",
                .product(name: "BitcoinDevKit", package: "bdk-swift"),
                .product(name: "SolanaSwift", package: "Solana.Swift"),
                .product(name: "TangemWalletCoreBinariesWrapper", package: "wallet-core-binaries-ios"),
                .product(name: "ScaleCodec", package: "ScaleCodec.swift"),
                .product(name: "stellarsdk", package: "stellar-ios-mac-sdk"),
                .product(name: "Hiero", package: "hiero-sdk-swift"),
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTestTarget(
            name: "TangemAnalyticsTests",
            dependencies: [
                "TangemAnalytics",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTestTarget(
            name: "TangemFoundationTests",
            dependencies: [
                "TangemFoundation",
            ]
        ),
        .tangemTestTarget(
            name: "TangemLoggerTests",
            dependencies: [
                "TangemLogger",
            ],
            swiftSettings: [
                // [REDACTED_TODO_COMMENT]
                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTestTarget(
            name: "TangemMobileWalletSdkTests",
            path: "TangemMobileWalletSdk/Tests",
            dependencies: [
                "TangemFoundation",
                "TangemMobileWalletSdk",
                "TrezorCrypto",
            ]
        ),
        .tangemTestTarget(
            name: "TangemNFTTests",
            dependencies: [
                "TangemNFT",
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
    if ProcessInfo.processInfo.environment["SWIFT_PACKAGE_BUILD_FOR_INTERNAL"] != nil {
        return BuildSettings(
            cSettings: [.define("INTERNAL", to: "1")],
            cxxSettings: [.define("INTERNAL", to: "1")],
            swiftSettings: [.define("INTERNAL")]
        )
    }

    return nil
}
