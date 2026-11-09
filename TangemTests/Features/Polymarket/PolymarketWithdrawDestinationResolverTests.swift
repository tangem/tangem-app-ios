//
//  PolymarketWithdrawDestinationResolverTests.swift
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

@Suite("PolymarketWithdrawDestinationResolver")
struct PolymarketWithdrawDestinationResolverTests {
    private let usdcPolygon = PolymarketUtilities.usdcTokenItem
    private let ethereum = TokenItem.blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))

    @Test("The first token the wallet shows in the bridge's currency becomes the destination")
    func firstMatchingTokenWins() async {
        let other = makeWalletModel(tokenItem: ethereum)
        let matching = makeWalletModel(tokenItem: usdcPolygon)

        let chosen = await chooseDestination(from: [other, matching])

        #expect(chosen === matching)
    }

    @Test("A joint account's token becomes the destination when it is the first match the wallet shows")
    func jointAccountBecomesDestination() async {
        let joint = makeWalletModel(tokenItem: usdcPolygon, accountType: .joint)
        let standard = makeWalletModel(tokenItem: usdcPolygon)

        let chosen = await chooseDestination(from: [joint, standard])

        #expect(chosen === joint)
    }

    @Test("A custom token in the bridge's currency is skipped for the next match")
    func customTokenIsSkipped() async {
        let custom = makeWalletModel(tokenItem: usdcPolygon, isCustom: true)
        let standard = makeWalletModel(tokenItem: usdcPolygon)

        let chosen = await chooseDestination(from: [custom, standard])

        #expect(chosen === standard)
    }

    @Test("An unreachable Express doesn't drop the destination")
    func unreachableExpressKeepsDestination() async {
        let matching = makeWalletModel(tokenItem: usdcPolygon)

        let chosen = await chooseDestination(
            from: [matching],
            expressAvailabilityProvider: SwapExpressAvailabilityProviderStub(swapState: .unavailable, updateState: .failed(error: URLError(.notConnectedToInternet)))
        )

        #expect(chosen === matching)
    }

    @Test("A token in another currency is never the destination, whatever account holds it")
    func nonMatchingCurrencyResolvesToNil() async {
        let chosen = await chooseDestination(from: [makeWalletModel(tokenItem: ethereum)])

        #expect(chosen == nil)
    }
}

// MARK: - Fixtures

private extension PolymarketWithdrawDestinationResolverTests {
    func chooseDestination(
        from walletModels: [any WalletModel],
        expressAvailabilityProvider: ExpressAvailabilityProvider = SwapExpressAvailabilityProviderStub()
    ) async -> (any WalletModel)? {
        await InjectedDependenciesIsolation.shared.run {
            let previousProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.expressAvailabilityProvider] = expressAvailabilityProvider
            defer { InjectedValues[\.expressAvailabilityProvider] = previousProvider }

            return PolymarketWithdrawDestinationResolver.chooseDestination(
                from: walletModels,
                userWalletInfo: SendSourceTokenStub().userWalletInfo
            )
        }
    }

    func makeWalletModel(tokenItem: TokenItem, accountType: AccountType = .crypto, isCustom: Bool = false) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            account: CryptoAccountModelMock(
                isMainAccount: false,
                accountType: accountType,
                onArchive: { _ in }
            ),
            isCustom: isCustom
        )
    }
}
