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
import TangemFoundation
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
    func preferredTokenWinsWithoutSwapAvailability() async {
        let preferred = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 50)
        let swapFallback = makeWalletModel(tokenItem: ethereum, fiatBalance: 500)

        let chosen = await chooseSource(
            from: [preferred, swapFallback],
            preferredCurrencies: [usdcPolygon.expressCurrency],
            expressAvailabilityProvider: expressUnreachable(for: usdcPolygon)
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("A funded preferred token without a fiat quote still wins over the swap fallback")
    func preferredWithoutQuoteStaysTransfer() async {
        // The transfer gate already guarantees a positive crypto balance —
        // a missing quote only hides it from the fiat comparison.
        let preferred = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 0)
        let swapFallback = makeWalletModel(tokenItem: ethereum, fiatBalance: 500)

        let chosen = await chooseSource(
            from: [preferred, swapFallback],
            preferredCurrencies: [usdcPolygon.expressCurrency],
            expressAvailabilityProvider: expressUnreachable(for: usdcPolygon)
        )

        #expect(chosen?.tokenItem == usdcPolygon)
    }

    @Test("A preferred token the app can't transfer is skipped for the swap fallback")
    func transferUnavailablePreferredSkipped() async {
        let preferred = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 50, availableBalance: .failure(nil))
        let swapFallback = makeWalletModel(tokenItem: ethereum, fiatBalance: 5)

        let chosen = await chooseSource(
            from: [preferred, swapFallback],
            preferredCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without a currency match the richest swap-available token wins; swap-unavailable ones never do")
    func fallbackRequiresSwapAvailability() async {
        let swapAvailable = makeWalletModel(tokenItem: ethereum, fiatBalance: 100)
        let swapUnavailable = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 999, availableBalance: .failure(nil))

        let chosen = await chooseSource(
            from: [swapAvailable, swapUnavailable],
            preferredCurrencies: []
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("With no positive fiat anywhere the first swap-available token still becomes the source")
    func nothingFundedFallsBackToFirstSwapAvailable() async {
        let unavailable = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 0, availableBalance: .failure(nil))
        let available = makeWalletModel(tokenItem: ethereum, fiatBalance: 0)

        let chosen = await chooseSource(
            from: [unavailable, available],
            preferredCurrencies: []
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("Without a single swap-available token the source stays unresolved")
    func noSwapAvailableTokensResolveToNil() async {
        let unavailable = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 999, availableBalance: .failure(nil))

        let chosen = await chooseSource(
            from: [unavailable],
            preferredCurrencies: []
        )

        #expect(chosen == nil)
    }

    @Test("A custom token in the Pay currency is never the transfer source, so the swap fallback is picked")
    func customTokenIsNotTransferSource() async {
        let custom = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 500, isCustom: true)
        let swapFallback = makeWalletModel(tokenItem: ethereum, fiatBalance: 5)

        let chosen = await chooseSource(
            from: [custom, swapFallback],
            preferredCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen?.tokenItem == ethereum)
    }

    @Test("A joint account never becomes the transfer source, however much of the Pay currency it holds")
    func jointAccountNeverBecomesTransferSource() async {
        let joint = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 999, accountType: .joint)
        let standard = makeWalletModel(tokenItem: usdcPolygon, fiatBalance: 1)

        let chosen = await chooseSource(
            from: [joint, standard],
            preferredCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen === standard)
    }

    @Test("A joint account never becomes the swap fallback either")
    func jointAccountNeverBecomesSwapFallback() async {
        let joint = makeWalletModel(tokenItem: ethereum, fiatBalance: 999, accountType: .joint)
        let standard = makeWalletModel(tokenItem: ethereum, fiatBalance: 1)

        let chosen = await chooseSource(
            from: [joint, standard],
            preferredCurrencies: [usdcPolygon.expressCurrency]
        )

        #expect(chosen === standard)
    }
}

// MARK: - Fixtures

private extension TangemPayAddFundsSourceResolverTests {
    func chooseSource(
        from walletModels: [any WalletModel],
        preferredCurrencies: Set<ExpressWalletCurrency>,
        expressAvailabilityProvider: ExpressAvailabilityProvider = SwapExpressAvailabilityProviderStub()
    ) async -> (any WalletModel)? {
        await InjectedDependenciesIsolation.shared.run {
            let previousProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.expressAvailabilityProvider] = expressAvailabilityProvider
            defer { InjectedValues[\.expressAvailabilityProvider] = previousProvider }

            return TangemPayAddFundsSourceResolver.chooseSource(
                from: walletModels,
                preferredCurrencies: preferredCurrencies,
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
        accountType: AccountType = .crypto,
        isCustom: Bool = false,
        availableBalance: TokenBalanceType = .loaded(1)
    ) -> WalletModelTestsMock {
        let walletModel = WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            fiatBalance: fiatBalance,
            account: CryptoAccountModelMock(
                isMainAccount: false,
                accountType: accountType,
                onArchive: { _ in }
            ),
            isCustom: isCustom
        )
        walletModel.availableBalanceProviderMock = TokenBalanceProviderTestsMock(balanceType: availableBalance)

        return walletModel
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
