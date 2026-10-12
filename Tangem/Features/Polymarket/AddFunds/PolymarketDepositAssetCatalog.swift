//
//  PolymarketDepositAssetCatalog.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPolymarket
import TangemSdk

enum PolymarketDepositAssetCatalog {
    static let entries: [Entry] = [
        usdcOnPolygon,
        usdcOnEthereum,
        usdcOnBase,
        usdcOnArbitrum,
        usdcOnOptimism,
        usdcOnBSC,
        usdcOnMonad,
        usdcOnHyperEVM,
        usdcOnSolana,
    ]
}

// MARK: - USDC

extension PolymarketDepositAssetCatalog {
    static let usdcOnPolygon = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "polygon-pos",
        derivationPath: PolymarketUtilities.derivationPath,
        bridgeChainId: "137",
        contractAddress: PolymarketUtilities.usdcContractAddress,
        decimalCount: 6
    )

    static let usdcOnEthereum = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "ethereum",
        derivationPath: PolymarketUtilities.derivationPath,
        bridgeChainId: "1",
        contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        decimalCount: 6
    )

    static let usdcOnBase = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "base",
        derivationPath: PolymarketUtilities.derivationPath,
        bridgeChainId: "8453",
        contractAddress: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
        decimalCount: 6
    )

    static let usdcOnArbitrum = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "arbitrum-one",
        derivationPath: PolymarketUtilities.derivationPath,
        bridgeChainId: "42161",
        contractAddress: "0xaf88d065e77c8cc2239327c5edb3a432268e5831",
        decimalCount: 6
    )

    static let usdcOnOptimism = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "optimistic-ethereum",
        derivationPath: PolymarketUtilities.derivationPath,
        bridgeChainId: "10",
        contractAddress: "0x0b2c639c533813f4aa9d7837caf62653d097ff85",
        decimalCount: 6
    )

    /// Binance-Peg USDC, the eighteen-decimal one the chain actually circulates.
    static let usdcOnBSC = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "binance-smart-chain",
        derivationPath: PolymarketUtilities.derivationPath,
        bridgeChainId: "56",
        contractAddress: "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
        decimalCount: 18
    )

    static let usdcOnMonad = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "monad",
        derivationPath: PolymarketUtilities.derivationPath,
        bridgeChainId: "143",
        contractAddress: "0x754704bc059f8c67012fed69bc8a327a5aafb603",
        decimalCount: 6
    )

    static let usdcOnHyperEVM = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "hyperevm",
        derivationPath: PolymarketUtilities.derivationPath,
        bridgeChainId: "999",
        contractAddress: "0xb88339cb7199b77e23db6e890353e22632ba630f",
        decimalCount: 6
    )

    static let usdcOnSolana = Entry(
        symbol: "USDC",
        coinId: "usd-coin",
        networkId: "solana",
        derivationPath: nil,
        bridgeChainId: "1151111081099710",
        contractAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        decimalCount: 6
    )
}

// MARK: - Accepted assets

extension PolymarketDepositAssetCatalog {
    static func acceptedAssets(from bridgeAssets: [PolymarketSupportedAsset]) -> [AcceptedAsset] {
        entries.compactMap { entry in
            acceptedAsset(for: entry, in: bridgeAssets).map { AcceptedAsset(entry: entry, bridgeAsset: $0) }
        }
    }

    static func acceptedAsset(for entry: Entry, in bridgeAssets: [PolymarketSupportedAsset]) -> PolymarketSupportedAsset? {
        bridgeAssets.first { entry.matches($0) }
    }
}

// MARK: - Nested types

extension PolymarketDepositAssetCatalog {
    struct Entry: Hashable {
        let symbol: String
        let coinId: String
        let networkId: String
        let derivationPath: DerivationPath?
        let bridgeChainId: String
        let contractAddress: String
        let decimalCount: Int
    }

    struct AcceptedAsset: Hashable {
        let entry: Entry
        let bridgeAsset: PolymarketSupportedAsset
    }
}

// MARK: - Token item

extension PolymarketDepositAssetCatalog.Entry {
    func makeTokenItem(supportedBlockchains: Set<Blockchain>) -> TokenItem? {
        guard let blockchain = supportedBlockchains.first(where: { $0.networkId == networkId && !$0.isTestnet }) else {
            return nil
        }

        return .token(
            Token(
                name: symbol,
                symbol: symbol,
                contractAddress: contractAddress,
                decimalCount: decimalCount,
                id: coinId,
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(blockchain, derivationPath: derivationPath)
        )
    }
}

// MARK: - Matching

private extension PolymarketDepositAssetCatalog.Entry {
    func matches(_ bridgeAsset: PolymarketSupportedAsset) -> Bool {
        guard
            bridgeAsset.chainId == bridgeChainId,
            bridgeAsset.token.decimalCount == decimalCount
        else {
            return false
        }

        switch bridgeAsset.family {
        case .evm:
            return bridgeAsset.token.address.caseInsensitiveCompare(contractAddress) == .orderedSame
        case .svm, .btc, .tron:
            return bridgeAsset.token.address == contractAddress
        }
    }
}
