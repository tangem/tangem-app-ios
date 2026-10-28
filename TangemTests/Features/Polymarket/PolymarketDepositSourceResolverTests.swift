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
import TangemFoundation
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
    func richestAcceptedNetworkWins() async {
        let poorer = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 10)
        let richer = WalletModelTestsMock(tokenItem: usdcBase, isEmpty: false, fiatBalance: 500)

        let chosen = await chooseSource(
            from: [poorer, richer],
            depositCurrencies: [usdcPolygon.expressCurrency, usdcBase.expressCurrency]
        )

        #expect(chosen?.tokenItem == usdcBase)
    }

    @Test("A network the bridge does not accept is no transfer source, however rich it is")
    func unacceptedNetworkIsNoTransferSource() async {
        let accepted = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 10)
        let unaccepted = WalletModelTestsMock(tokenItem: usdcBase, isEmpty: false, fiatBalance: 500)

        let chosen = await chooseSource(
            from: [accepted, unaccepted],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("The bridge's own currency stays the transfer source even when Express can't swap it")
    func depositCurrencyWinsWithoutSwapAvailability() async {
        let matching = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 50)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 500)

        let chosen = await chooseSource(
            from: [matching, swapFallback],
            depositCurrencies: [usdcPolygon.expressCurrency],
            expressAvailabilityProvider: expressUnreachable(for: usdcPolygon)
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("A funded deposit-currency token without a fiat quote still wins over the swap fallback")
    func matchingWithoutQuoteStaysTransfer() async {
        let matching = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 0)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 500)

        let chosen = await chooseSource(
            from: [matching, swapFallback],
            depositCurrencies: [usdcPolygon.expressCurrency],
            expressAvailabilityProvider: expressUnreachable(for: usdcPolygon)
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("A deposit-currency token the app can't transfer is skipped for the swap fallback")
    func transferUnavailableMatchingSkipped() async {
        let matching = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 50)
        matching.sendingRestrictionsMock = .blockchainUnreachable
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 5)

        let chosen = await chooseSource(
            from: [matching, swapFallback],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without the deposit currency the richest swap-available token wins; swap-unavailable ones never do")
    func fallbackRequiresSwapAvailability() async {
        let swapAvailable = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 100)
        let swapUnavailable = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 999)
        swapUnavailable.sendingRestrictionsMock = .blockchainUnreachable

        let chosen = await chooseSource(
            from: [swapAvailable, swapUnavailable],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("With no positive fiat anywhere the first swap-available token still becomes the source")
    func nothingFundedFallsBackToFirstSwapAvailable() async {
        let unavailable = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 0)
        unavailable.sendingRestrictionsMock = .blockchainUnreachable
        let available = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 0)

        let chosen = await chooseSource(
            from: [unavailable, available],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without a single swap-available token the source stays unresolved")
    func noSwapAvailableTokensResolveToNil() async {
        let unavailable = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 999)
        unavailable.sendingRestrictionsMock = .blockchainUnreachable

        let chosen = await chooseSource(
            from: [unavailable],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen == nil)
    }

    @Test("A custom token in the deposit currency is never the transfer source, so the swap fallback is picked")
    func customTokenIsNotTransferSource() async {
        let custom = WalletModelTestsMock(tokenItem: usdcPolygon, isEmpty: false, fiatBalance: 500, isCustom: true)
        let swapFallback = WalletModelTestsMock(tokenItem: ethereum, isEmpty: false, fiatBalance: 5)

        let chosen = await chooseSource(
            from: [custom, swapFallback],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("A joint account never becomes the transfer source, however much of the deposit currency it holds")
    func jointAccountNeverBecomesTransferSource() async {
        let joint = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 999, accountType: .joint)
        let standard = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 1)

        let chosen = await chooseSource(
            from: [joint, standard],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen === standard)
    }

    @Test("A joint account never becomes the swap fallback either")
    func jointAccountNeverBecomesSwapFallback() async {
        let joint = makeWalletModel(tokenItem: ethereum, fiatBalance: 999, accountType: .joint)
        let standard = makeWalletModel(tokenItem: ethereum, fiatBalance: 1)

        let chosen = await chooseSource(
            from: [joint, standard],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen === standard)
    }

    @Test("With every funded token sitting in a joint account the source stays unresolved")
    func jointOnlyWalletResolvesToNil() async {
        let joint = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 999, accountType: .joint)

        let chosen = await chooseSource(
            from: [joint],
            depositCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen == nil)
    }
}

// MARK: - Fixtures

private extension PolymarketDepositSourceResolverTests {
    func chooseSource(
        from walletModels: [any WalletModel],
        depositCurrencies: Set<ExpressWalletCurrency>,
        expressAvailabilityProvider: ExpressAvailabilityProvider = SwapExpressAvailabilityProviderStub()
    ) async -> (any WalletModel)? {
        await InjectedDependenciesIsolation.shared.run {
            let previousProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.expressAvailabilityProvider] = expressAvailabilityProvider
            defer { InjectedValues[\.expressAvailabilityProvider] = previousProvider }

            return PolymarketDepositSourceResolver.chooseSource(
                from: walletModels,
                depositCurrencies: depositCurrencies,
                userWalletInfo: makeUserWalletInfo()
            )
        }
    }

    func expressUnreachable(for tokenItem: TokenItem) -> ExpressAvailabilityProvider {
        SwapExpressAvailabilityProviderStub(swapStates: [tokenItem: .unavailable], updateState: .failed(error: URLError(.notConnectedToInternet)))
    }

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

    func makeUserWalletInfo() -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }
}
