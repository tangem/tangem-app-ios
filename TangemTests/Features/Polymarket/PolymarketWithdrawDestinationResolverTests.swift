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
    func firstMatchingTokenWins() {
        let other = makeWalletModel(tokenItem: ethereum)
        let matching = makeWalletModel(tokenItem: usdcPolygon)

        let chosen = PolymarketWithdrawDestinationResolver.chooseDestination(from: [other, matching])

        #expect(chosen === matching)
    }

    @Test("A joint account never becomes the destination, even when it is the first match the wallet shows")
    func jointAccountNeverBecomesDestination() {
        let joint = makeWalletModel(tokenItem: usdcPolygon, accountType: .joint)
        let standard = makeWalletModel(tokenItem: usdcPolygon)

        let chosen = PolymarketWithdrawDestinationResolver.chooseDestination(from: [joint, standard])

        #expect(chosen === standard)
    }

    @Test("With the bridge's currency only in a joint account the destination stays unresolved")
    func jointOnlyMatchResolvesToNil() {
        let joint = makeWalletModel(tokenItem: usdcPolygon, accountType: .joint)

        let chosen = PolymarketWithdrawDestinationResolver.chooseDestination(from: [joint])

        #expect(chosen == nil)
    }

    @Test("A token in another currency is never the destination, whatever account holds it")
    func nonMatchingCurrencyResolvesToNil() {
        let chosen = PolymarketWithdrawDestinationResolver.chooseDestination(from: [makeWalletModel(tokenItem: ethereum)])

        #expect(chosen == nil)
    }
}

// MARK: - Fixtures

private extension PolymarketWithdrawDestinationResolverTests {
    func makeWalletModel(tokenItem: TokenItem, accountType: AccountType = .crypto) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            account: CryptoAccountModelMock(
                isMainAccount: false,
                accountType: accountType,
                onArchive: { _ in }
            )
        )
    }
}
