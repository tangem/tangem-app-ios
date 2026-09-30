//
//  PolymarketDepositAssetCatalogTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
import TangemPolymarket
import TangemSdk
@testable import Tangem

@Suite("PolymarketDepositAssetCatalog")
struct PolymarketDepositAssetCatalogTests {
    @Test("Only what the bridge lists is accepted, and in the catalog's own order")
    func picksTheListedEntriesInCatalogOrder() {
        let accepted = PolymarketDepositAssetCatalog.acceptedAssets(from: [
            solanaUSDC,
            polygonSecondUSDC,
            baseUSDC,
            bscUSDC,
            ethereumUSDC,
            polygonUSDCe,
            polygonUSDC,
        ])

        #expect(accepted.map(\.entry) == [
            PolymarketDepositAssetCatalog.usdcOnPolygon,
            PolymarketDepositAssetCatalog.usdcOnEthereum,
            PolymarketDepositAssetCatalog.usdcOnBase,
            PolymarketDepositAssetCatalog.usdcOnBSC,
            PolymarketDepositAssetCatalog.usdcOnSolana,
        ])
        #expect(accepted.map(\.bridgeAsset.token.address) == [
            polygonUSDC.token.address,
            ethereumUSDC.token.address,
            baseUSDC.token.address,
            bscUSDC.token.address,
            solanaUSDC.token.address,
        ])
    }

    @Test("Every entry names a distinct asset — no two rows share a chain and a contract")
    func entriesNameDistinctAssets() {
        let keys = PolymarketDepositAssetCatalog.entries.map {
            "\($0.bridgeChainId)/\($0.contractAddress.lowercased())"
        }

        #expect(Set(keys).count == keys.count)
    }

    @Test("Hex contracts are stored lowercase, the form the app's token identity uses")
    func hexContractsAreStoredLowercase() {
        let hex = PolymarketDepositAssetCatalog.entries.filter { $0.contractAddress.lowercased().hasPrefix("0x") }

        #expect(hex.isNotEmpty)
        #expect(hex.allSatisfy { $0.contractAddress == $0.contractAddress.lowercased() })
    }

    @Test("Another USDC contract on a catalogued chain is not accepted")
    func rejectsAnotherContractOnTheSameChain() {
        let accepted = PolymarketDepositAssetCatalog.acceptedAssets(from: [polygonSecondUSDC, polygonUSDCe])

        #expect(accepted.isEmpty)
    }

    @Test("A catalogued contract listed under another catalogued chain is not accepted")
    func rejectsCataloguedContractOnAnotherChain() {
        let polygonContractOnBase = makeBridgeAsset(
            chainId: "8453",
            chainName: "Base",
            family: .evm,
            address: PolymarketUtilities.usdcContractAddress,
            decimalCount: 6
        )

        #expect(PolymarketDepositAssetCatalog.acceptedAssets(from: [polygonContractOnBase]).isEmpty)
    }

    @Test("A catalogued contract whose decimals the bridge reports differently is not accepted")
    func rejectsCataloguedContractWithForeignDecimals() {
        let inflated = makeBridgeAsset(
            chainId: "8453",
            chainName: "Base",
            family: .evm,
            address: baseUSDC.token.address,
            decimalCount: 18
        )

        #expect(PolymarketDepositAssetCatalog.acceptedAssets(from: [inflated]).isEmpty)
    }

    @Test("A checksummed EVM contract matches the catalog's lowercase form and carries the bridge's own data")
    func matchesEvmContractIgnoringChecksumCase() throws {
        let checksummed = makeBridgeAsset(
            chainId: "1",
            chainName: "Ethereum",
            family: .evm,
            address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
            decimalCount: 6,
            minCheckoutUSD: Decimal(string: "3")!
        )

        let accepted = try #require(PolymarketDepositAssetCatalog.acceptedAssets(from: [checksummed]).first)

        #expect(accepted.entry == PolymarketDepositAssetCatalog.usdcOnEthereum)
        #expect(accepted.bridgeAsset.minCheckoutUSD == Decimal(string: "3")!)
    }

    @Test("A Solana mint in another case is a different mint and is not accepted")
    func rejectsSolanaMintInAnotherCase() {
        let lowercased = makeBridgeAsset(
            chainId: "1151111081099710",
            chainName: "Solana",
            family: .svm,
            address: solanaUSDC.token.address.lowercased(),
            decimalCount: 6
        )

        #expect(PolymarketDepositAssetCatalog.acceptedAssets(from: [lowercased]).isEmpty)
    }

    @Test("A bridge that lists nothing the catalog names yields nothing")
    func rejectsEverythingOutsideTheCatalog() {
        #expect(PolymarketDepositAssetCatalog.acceptedAssets(from: [polygonUSDCe]).isEmpty)
        #expect(PolymarketDepositAssetCatalog.acceptedAssets(from: []).isEmpty)
    }
}

// MARK: - Token items

@Suite("PolymarketDepositAssetCatalog token items")
struct PolymarketDepositAssetCatalogTokenItemTests {
    @Test("The Polygon entry builds the very token item the deposit flow was pinned to")
    func polygonEntryBuildsTheTokenItemTheFlowUsed() throws {
        let tokenItem = try #require(
            PolymarketDepositAssetCatalog.usdcOnPolygon.makeTokenItem(
                supportedBlockchains: [PolymarketUtilities.blockchain]
            )
        )

        #expect(tokenItem == PolymarketUtilities.usdcTokenItem)
    }

    @Test(
        "Solana takes the curve from the wallet's own blockchain instead of a baked-in one",
        arguments: [EllipticCurve.ed25519, .ed25519_slip0010]
    )
    func solanaTakesTheWalletsCurve(curve: EllipticCurve) throws {
        let solana = Blockchain.solana(curve: curve, testnet: false)

        let tokenItem = try #require(
            PolymarketDepositAssetCatalog.usdcOnSolana.makeTokenItem(supportedBlockchains: [solana])
        )

        #expect(tokenItem.blockchain == solana)
        #expect(tokenItem.contractAddress == PolymarketDepositAssetCatalog.usdcOnSolana.contractAddress)
    }

    @Test("Solana carries no derivation path, because the one the account uses is an Ethereum path")
    func solanaCarriesNoDerivationPath() throws {
        let tokenItem = try #require(
            PolymarketDepositAssetCatalog.usdcOnSolana.makeTokenItem(
                supportedBlockchains: [.solana(curve: .ed25519_slip0010, testnet: false)]
            )
        )

        #expect(tokenItem.blockchainNetwork.derivationPath == nil)
        #expect(PolymarketUtilities.usdcTokenItem.blockchainNetwork.derivationPath != nil)
    }

    @Test("A testnet blockchain never becomes a deposit destination, the bridge is mainnet only")
    func testnetIsNeverADestination() {
        #expect(
            PolymarketDepositAssetCatalog.usdcOnPolygon.makeTokenItem(
                supportedBlockchains: [.polygon(testnet: true)]
            ) == nil
        )
    }

    @Test("Every entry resolves against the blockchains the app ships, so a typo cannot silently drop a network")
    func everyEntryResolvesItsNetwork() {
        let unresolved = PolymarketDepositAssetCatalog.entries
            .filter { $0.makeTokenItem(supportedBlockchains: SupportedBlockchains.all) == nil }
            .map(\.networkId)

        #expect(unresolved.isEmpty)
    }

    @Test("An EVM entry repeats the chain id its own blockchain already carries")
    func evmEntriesRepeatTheBlockchainChainId() throws {
        let evmEntries = try PolymarketDepositAssetCatalog.entries.compactMap { entry -> (String, String, Int)? in
            let tokenItem = try #require(entry.makeTokenItem(supportedBlockchains: SupportedBlockchains.all))

            return tokenItem.blockchain.chainId.map { (entry.networkId, entry.bridgeChainId, $0) }
        }

        #expect(evmEntries.count == PolymarketDepositAssetCatalog.entries.count - 1)

        for (networkId, bridgeChainId, chainId) in evmEntries {
            #expect(bridgeChainId == "\(chainId)", "\(networkId) names a chain id its blockchain does not")
        }
    }

    @Test("A network the wallet does not support has no token item")
    func unsupportedNetworkHasNoTokenItem() {
        #expect(PolymarketDepositAssetCatalog.usdcOnBase.makeTokenItem(supportedBlockchains: []) == nil)
        #expect(
            PolymarketDepositAssetCatalog.usdcOnBase.makeTokenItem(
                supportedBlockchains: [PolymarketUtilities.blockchain]
            ) == nil
        )
    }
}

// MARK: - Bridge assets

private extension PolymarketDepositAssetCatalogTests {
    var polygonUSDC: PolymarketSupportedAsset {
        makeBridgeAsset(
            chainId: "137",
            chainName: "Polygon",
            family: .evm,
            address: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
            decimalCount: 6
        )
    }

    var polygonSecondUSDC: PolymarketSupportedAsset {
        makeBridgeAsset(
            chainId: "137",
            chainName: "Polygon",
            family: .evm,
            address: "0x4318CB63A2b8edf2De971E2F17F77097e499459D",
            decimalCount: 6
        )
    }

    var polygonUSDCe: PolymarketSupportedAsset {
        makeBridgeAsset(
            chainId: "137",
            chainName: "Polygon",
            family: .evm,
            address: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
            decimalCount: 6,
            symbol: "USDC.e"
        )
    }

    var ethereumUSDC: PolymarketSupportedAsset {
        makeBridgeAsset(
            chainId: "1",
            chainName: "Ethereum",
            family: .evm,
            address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
            decimalCount: 6,
            minCheckoutUSD: Decimal(string: "3")!
        )
    }

    var baseUSDC: PolymarketSupportedAsset {
        makeBridgeAsset(
            chainId: "8453",
            chainName: "Base",
            family: .evm,
            address: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
            decimalCount: 6
        )
    }

    var solanaUSDC: PolymarketSupportedAsset {
        makeBridgeAsset(
            chainId: "1151111081099710",
            chainName: "Solana",
            family: .svm,
            address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            decimalCount: 6
        )
    }

    var bscUSDC: PolymarketSupportedAsset {
        makeBridgeAsset(
            chainId: "56",
            chainName: "BNB Smart Chain",
            family: .evm,
            address: "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
            decimalCount: 18
        )
    }

    func makeBridgeAsset(
        chainId: String,
        chainName: String,
        family: PolymarketChainFamily,
        address: String,
        decimalCount: Int,
        symbol: String = "USDC",
        minCheckoutUSD: Decimal = Decimal(string: "2")!
    ) -> PolymarketSupportedAsset {
        PolymarketSupportedAsset(
            chainId: chainId,
            chainName: chainName,
            family: family,
            token: PolymarketSupportedAsset.Token(
                name: symbol,
                symbol: symbol,
                address: address,
                decimalCount: decimalCount
            ),
            minCheckoutUSD: minCheckoutUSD
        )
    }
}
