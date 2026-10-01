//
//  PolymarketDepositNetworkResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("PolymarketDepositNetworkResolver")
struct PolymarketDepositNetworkResolverTests {
    @Test("One row per network, in the order the targets arrive, listing that network's symbols")
    func groupsTargetsIntoNetworks() throws {
        let networks = PolymarketDepositNetworkResolver.resolve(depositTargets: [
            try makeTarget(PolymarketDepositAssetCatalog.usdcOnBase, fundingAddress: evmAddress),
            try makeTarget(PolymarketDepositAssetCatalog.usdcOnPolygon, fundingAddress: evmAddress),
            try makeTarget(PolymarketDepositAssetCatalog.usdcOnSolana, fundingAddress: solanaAddress),
        ])

        #expect(networks.map(\.networkId) == ["base", "polygon-pos", "solana"])
        #expect(networks.map(\.subtitle) == ["USDC", "USDC", "USDC"])
        #expect(networks.map(\.receiveInput.depositAddress) == [evmAddress, evmAddress, solanaAddress])
    }

    @Test("Every token of a network lands on one screen, addressed once")
    func mergesTheTokensOfOneNetwork() throws {
        let networks = PolymarketDepositNetworkResolver.resolve(depositTargets: [
            try makeTarget(PolymarketDepositAssetCatalog.usdcOnPolygon, fundingAddress: evmAddress),
            try makeTarget(PolymarketDepositAssetCatalog.usdcOnPolygon, symbol: "USDT", fundingAddress: evmAddress),
        ])

        let polygon = try #require(networks.first)

        #expect(networks.count == 1)
        #expect(polygon.receiveInput.tokens.map(\.currencySymbol) == ["USDC", "USDT"])
        #expect(polygon.subtitle == "USDC, USDT")
    }

    @Test("The printed minimum is the strictest of the network's tokens, not the first one's")
    func printsTheStrictestMinimum() throws {
        let networks = PolymarketDepositNetworkResolver.resolve(depositTargets: [
            try makeTarget(PolymarketDepositAssetCatalog.usdcOnPolygon, minCheckoutUSD: 2),
            try makeTarget(PolymarketDepositAssetCatalog.usdcOnPolygon, symbol: "USDT", minCheckoutUSD: 7),
        ])

        let polygon = try #require(networks.first)
        let lenient = BalanceFormatter().formatFiatBalance(Decimal(2), currencyCode: AppConstants.usdCurrencyCode)
        let strict = BalanceFormatter().formatFiatBalance(Decimal(7), currencyCode: AppConstants.usdCurrencyCode)

        #expect(polygon.receiveInput.minimumDepositFormatted.contains(strict))
        #expect(!polygon.receiveInput.minimumDepositFormatted.contains(lenient))
    }

    @Test("Without targets there are no networks to choose from")
    func noTargetsNoNetworks() {
        #expect(PolymarketDepositNetworkResolver.resolve(depositTargets: []).isEmpty)
    }

    @Test("A screen that would name one network for tokens of several is not built at all")
    func receiveInputRefusesTokensOfSeveralNetworks() throws {
        let polygon = try makeTarget(PolymarketDepositAssetCatalog.usdcOnPolygon).tokenItem
        let base = try makeTarget(PolymarketDepositAssetCatalog.usdcOnBase).tokenItem

        #expect(makeReceiveInput(tokens: [polygon, base]) == nil)
        #expect(makeReceiveInput(tokens: []) == nil)
        #expect(makeReceiveInput(tokens: [polygon])?.primaryToken == polygon)
    }

    @Test("The first token speaks for the screen and the rest keep the order they came in")
    func receiveInputKeepsTheOrderOfItsTokens() throws {
        let usdc = try makeTarget(PolymarketDepositAssetCatalog.usdcOnPolygon).tokenItem
        let usdt = try makeTarget(PolymarketDepositAssetCatalog.usdcOnPolygon, symbol: "USDT").tokenItem

        let input = try #require(makeReceiveInput(tokens: [usdc, usdt]))

        #expect(input.primaryToken == usdc)
        #expect(input.otherTokens == [usdt])
        #expect(input.tokens == [usdc, usdt])
        #expect(input.blockchain == PolymarketUtilities.blockchain)
    }
}

// MARK: - Fixtures

private extension PolymarketDepositNetworkResolverTests {
    var evmAddress: String { "0x2222222222222222222222222222222222222222" }
    var solanaAddress: String { "So11111111111111111111111111111111111111112" }

    func makeReceiveInput(tokens: [TokenItem]) -> PolymarketReceiveSheetViewModel.Input? {
        PolymarketReceiveSheetViewModel.Input(
            depositAddress: evmAddress,
            minimumDepositFormatted: "$2.00",
            tokens: tokens
        )
    }

    var supportedBlockchains: Set<Blockchain> {
        [
            PolymarketUtilities.blockchain,
            .base(testnet: false),
            .solana(curve: .ed25519_slip0010, testnet: false),
        ]
    }

    func makeTarget(
        _ entry: PolymarketDepositAssetCatalog.Entry,
        symbol: String? = nil,
        minCheckoutUSD: Decimal = 2,
        fundingAddress: String = "0x2222222222222222222222222222222222222222"
    ) throws -> PolymarketAccountFundsInteractor.DepositTarget {
        let entry = symbol.map { symbol in
            PolymarketDepositAssetCatalog.Entry(
                symbol: symbol,
                coinId: "tether",
                networkId: entry.networkId,
                derivationPath: entry.derivationPath,
                bridgeChainId: entry.bridgeChainId,
                contractAddress: "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",
                decimalCount: entry.decimalCount
            )
        } ?? entry

        let tokenItem = try #require(entry.makeTokenItem(supportedBlockchains: supportedBlockchains))

        return PolymarketAccountFundsInteractor.DepositTarget(
            entry: entry,
            tokenItem: tokenItem,
            minCheckoutUSD: minCheckoutUSD,
            fundingAddress: fundingAddress
        )
    }
}
