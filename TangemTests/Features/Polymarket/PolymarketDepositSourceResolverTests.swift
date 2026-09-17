//
//  PolymarketDepositSourceResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
import TangemExpress
import TangemPolymarket
@testable import Tangem

@Suite("PolymarketDepositSourceResolver")
struct PolymarketDepositSourceResolverTests {
    private let usdcPolygon = PolymarketUtilities.usdcTokenItem
    private let ethereum = TokenItem.blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))

    @Test("The bridge's own currency stays the transfer source even when Express can't swap it")
    func depositCurrencyWinsWithoutSwapAvailability() {
        let matching = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 50)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 500)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [matching, swapFallback],
            depositCurrency: usdcPolygon.expressCurrency,
            availabilityChecker: FundingSourceAvailabilityCheckerStub(
                transferAvailable: [matching.id],
                swapAvailable: [swapFallback.id]
            )
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("A funded deposit-currency token without a fiat quote still wins over the swap fallback")
    func matchingWithoutQuoteStaysTransfer() {
        let matching = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 0)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 500)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [matching, swapFallback],
            depositCurrency: usdcPolygon.expressCurrency,
            availabilityChecker: FundingSourceAvailabilityCheckerStub(
                transferAvailable: [matching.id],
                swapAvailable: [swapFallback.id]
            )
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("A deposit-currency token the app can't transfer is skipped for the swap fallback")
    func transferUnavailableMatchingSkipped() {
        let matching = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 50)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 5)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [matching, swapFallback],
            depositCurrency: usdcPolygon.expressCurrency,
            availabilityChecker: FundingSourceAvailabilityCheckerStub(swapAvailable: [swapFallback.id])
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without the deposit currency the richest swap-available token wins; swap-unavailable ones never do")
    func fallbackRequiresSwapAvailability() {
        let swapAvailable = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 100)
        let swapUnavailable = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 999)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [swapAvailable, swapUnavailable],
            depositCurrency: usdcPolygon.expressCurrency,
            availabilityChecker: FundingSourceAvailabilityCheckerStub(swapAvailable: [swapAvailable.id])
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("With no positive fiat anywhere the first swap-available token still becomes the source")
    func nothingFundedFallsBackToFirstSwapAvailable() {
        let unavailable = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 0)
        let available = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 0)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [unavailable, available],
            depositCurrency: usdcPolygon.expressCurrency,
            availabilityChecker: FundingSourceAvailabilityCheckerStub(swapAvailable: [available.id])
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without a single swap-available token the source stays unresolved")
    func noSwapAvailableTokensResolveToNil() {
        let unavailable = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 999)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [unavailable],
            depositCurrency: usdcPolygon.expressCurrency,
            availabilityChecker: FundingSourceAvailabilityCheckerStub()
        )

        #expect(chosen == nil)
    }
}
