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

    private let usdcBase = TokenItem.accountToken(
        symbol: "USDC",
        contract: PolymarketDepositAssetCatalog.usdcOnBase.contractAddress,
        blockchain: .base(testnet: false)
    )

    @Test("With several accepted networks the richest of them is preselected, not the first")
    func richestAcceptedNetworkWins() {
        let poorer = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 10)
        let richer = WalletModelTestsMock(tokenItem: usdcBase, isEmpty: false, fiatBalance: 500)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [poorer, richer],
            depositCurrencies: [usdcPolygon.expressCurrency, usdcBase.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(
                transferAvailable: [poorer.id, richer.id],
                swapAvailable: []
            )
        )

        #expect(chosen?.tokenItem == usdcBase)
    }

    @Test("A network the bridge does not accept is no transfer source, however rich it is")
    func unacceptedNetworkIsNoTransferSource() {
        let accepted = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 10)
        let unaccepted = WalletModelTestsMock(tokenItem: usdcBase, isEmpty: false, fiatBalance: 500)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [accepted, unaccepted],
            depositCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(
                transferAvailable: [accepted.id, unaccepted.id],
                swapAvailable: []
            )
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("The bridge's own currency stays the transfer source even when Express can't swap it")
    func depositCurrencyWinsWithoutSwapAvailability() {
        let matching = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 50)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 500)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [matching, swapFallback],
            depositCurrencies: [usdcPolygon.expressCurrency],
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
            depositCurrencies: [usdcPolygon.expressCurrency],
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
            depositCurrencies: [usdcPolygon.expressCurrency],
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
            depositCurrencies: [usdcPolygon.expressCurrency],
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
            depositCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(swapAvailable: [available.id])
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without a single swap-available token the source stays unresolved")
    func noSwapAvailableTokensResolveToNil() {
        let unavailable = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 999)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [unavailable],
            depositCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub()
        )

        #expect(chosen == nil)
    }

    @Test("A joint account never becomes the transfer source, however much of the deposit currency it holds")
    func jointAccountNeverBecomesTransferSource() {
        let joint = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 999, accountType: .joint)
        let standard = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 1)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [joint, standard],
            depositCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(
                transferAvailable: [joint.id, standard.id],
                swapAvailable: [joint.id, standard.id]
            )
        )

        #expect(chosen === standard)
    }

    @Test("A joint account never becomes the swap fallback either")
    func jointAccountNeverBecomesSwapFallback() {
        let joint = makeWalletModel(tokenItem: ethereum, fiatBalance: 999, accountType: .joint)
        let standard = makeWalletModel(tokenItem: ethereum, fiatBalance: 1)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [joint, standard],
            depositCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(swapAvailable: [joint.id, standard.id])
        )

        #expect(chosen === standard)
    }

    @Test("With every funded token sitting in a joint account the source stays unresolved")
    func jointOnlyWalletResolvesToNil() {
        let joint = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 999, accountType: .joint)

        let chosen = PolymarketDepositSourceResolver.chooseSource(
            from: [joint],
            depositCurrencies: [usdcPolygon.expressCurrency],
            availabilityChecker: FundingSourceAvailabilityCheckerStub(
                transferAvailable: [joint.id],
                swapAvailable: [joint.id]
            )
        )

        #expect(chosen == nil)
    }
}

// MARK: - Fixtures

private extension PolymarketDepositSourceResolverTests {
    func makeWalletModel(
        tokenItem: TokenItem,
        fiatBalance: Decimal,
        accountType: AccountType = .crypto
    ) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            fiatBalance: fiatBalance,
            account: CryptoAccountModelMock(
                isMainAccount: false,
                accountType: accountType,
                onArchive: { _ in }
            )
        )
    }
}
