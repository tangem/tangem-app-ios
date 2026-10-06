//
//  CommonTotalBalanceProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Main screen total balance")
struct CommonTotalBalanceProviderTests {
    @Test("A Polymarket account adds its total, open positions included, not just the available cash")
    func polymarketAddsItsTotal() {
        let sut = makeSUT(polymarketState: .active, polymarketAvailable: 10, polymarketTotal: 25)

        #expect(sut.totalBalance == .loaded(balance: 30))
    }

    @Test("A Polymarket account the user cannot see adds nothing")
    func hiddenPolymarketAddsNothing() {
        let sut = makeSUT(polymarketState: .unavailable, polymarketAvailable: 10, polymarketTotal: 25)

        #expect(sut.totalBalance == .loaded(balance: 5))
    }
}

// MARK: - Helpers

private extension CommonTotalBalanceProviderTests {
    func makeSUT(
        cryptoBalance: Decimal = 5,
        polymarketState: PolymarketAccountState,
        polymarketAvailable: Decimal,
        polymarketTotal: Decimal
    ) -> CommonTotalBalanceProvider {
        let cryptoTotalBalanceProvider = TotalBalanceProviderTestsMock()
        cryptoTotalBalanceProvider.totalBalance = .loaded(balance: cryptoBalance)
        cryptoTotalBalanceProvider.sendUpdate()

        let cryptoAccount = CryptoAccountModelMock(
            isMainAccount: true,
            totalBalanceProvider: cryptoTotalBalanceProvider,
            onArchive: { _ in }
        )

        let polymarketAccount = PolymarketAccountModelStub(
            state: polymarketState,
            fiatAvailableBalanceProvider: TokenBalanceProviderTestsMock(balance: polymarketAvailable),
            fiatTotalTokenBalanceProvider: TokenBalanceProviderTestsMock(balance: polymarketTotal)
        )

        let accountModelsManager = AccountModelsManagerStub(accounts: [
            .standard(.single(cryptoAccount)),
            .polymarket(polymarketAccount),
        ])

        return CommonTotalBalanceProvider(
            accountModelsManager: accountModelsManager,
            analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger()
        )
    }
}
