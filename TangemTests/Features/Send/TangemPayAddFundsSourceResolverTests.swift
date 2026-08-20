//
//  TangemPayAddFundsSourceResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
import TangemExpress
@testable import Tangem

@Suite("TangemPayAddFundsSourceResolver")
struct TangemPayAddFundsSourceResolverTests {
    private let usdcPolygon = TokenItem.token(
        Token(
            name: "USDC",
            symbol: "USDC",
            contractAddress: "0xUSDC",
            decimalCount: 6,
            metadata: .fungibleTokenMetadata
        ),
        BlockchainNetwork(.polygon(testnet: false), derivationPath: nil)
    )

    private let ethereum = TokenItem.blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))

    @Test("A currency-matched token stays the transfer source even when Express can't swap it")
    func preferredTokenWinsWithoutSwapAvailability() {
        let preferred = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 50)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 500)

        let chosen = TangemPayAddFundsSourceResolver.chooseSource(
            from: [preferred, swapFallback],
            preferredCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(
                transferAvailable: [preferred.id],
                swapAvailable: [swapFallback.id]
            )
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("A funded preferred token without a fiat quote still wins over the swap fallback")
    func preferredWithoutQuoteStaysTransfer() {
        // The transfer gate already guarantees a positive crypto balance —
        // a missing quote only hides it from the fiat comparison.
        let preferred = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 0)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 500)

        let chosen = TangemPayAddFundsSourceResolver.chooseSource(
            from: [preferred, swapFallback],
            preferredCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(
                transferAvailable: [preferred.id],
                swapAvailable: [swapFallback.id]
            )
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("A preferred token the app can't transfer is skipped for the swap fallback")
    func transferUnavailablePreferredSkipped() {
        let preferred = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 50)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 5)

        let chosen = TangemPayAddFundsSourceResolver.chooseSource(
            from: [preferred, swapFallback],
            preferredCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(swapAvailable: [swapFallback.id])
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without a currency match the richest swap-available token wins; swap-unavailable ones never do")
    func fallbackRequiresSwapAvailability() {
        let swapAvailable = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 100)
        let swapUnavailable = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 999)

        let chosen = TangemPayAddFundsSourceResolver.chooseSource(
            from: [swapAvailable, swapUnavailable],
            preferredCurrencies: [],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(swapAvailable: [swapAvailable.id])
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("With no positive fiat anywhere the first swap-available token still becomes the source")
    func nothingFundedFallsBackToFirstSwapAvailable() {
        let unavailable = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 0)
        let available = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 0)

        let chosen = TangemPayAddFundsSourceResolver.chooseSource(
            from: [unavailable, available],
            preferredCurrencies: [],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(swapAvailable: [available.id])
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without a single swap-available token the source stays unresolved")
    func noSwapAvailableTokensResolveToNil() {
        let unavailable = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 999)

        let chosen = TangemPayAddFundsSourceResolver.chooseSource(
            from: [unavailable],
            preferredCurrencies: [],
            availabilityChecker: FundingSourceAvailabilityCheckerStub()
        )

        #expect(chosen == nil)
    }
}

// MARK: - Stubs

private struct FundingSourceAvailabilityCheckerStub: FundingSourceAvailabilityChecker {
    var transferAvailable: Set<WalletModelId> = []
    var swapAvailable: Set<WalletModelId> = []

    func isTransferAvailable(walletModel: any WalletModel) -> Bool {
        transferAvailable.contains(walletModel.id)
    }

    func isSwapAvailable(walletModel: any WalletModel) -> Bool {
        swapAvailable.contains(walletModel.id)
    }
}
