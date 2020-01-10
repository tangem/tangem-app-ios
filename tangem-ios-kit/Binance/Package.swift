// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "BinanceChain",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v11),
        .tvOS(.v11),
        .watchOS(.v2)
    ],
    products: [
        .library(name: "BinanceChain", targets: ["binancechain"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.4.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.8.2"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.3.0"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.0"),
        .package(url: "https://github.com/malcommac/SwiftDate", from: "6.0.1"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.0.0"),
        .package(url: "https://github.com/Boilertalk/secp256k1.swift.git", from: "0.1.4"),
        .package(url: "https://github.com/mh7821/HDWallet.git", .revision("f246f8beaeee84356125e60f5550cf9a74191166"))
    ],
    targets: [
        .target(name: "binancechain",
                dependencies: ["SwiftProtobuf", "Alamofire", "SwiftyJSON", "Starscream", "HDWalletKit",
                               "XCGLogger", "secp256k1", "SwiftDate", "CryptoSwift"],
                path: "BinanceChain/Sources")
    ]
)
