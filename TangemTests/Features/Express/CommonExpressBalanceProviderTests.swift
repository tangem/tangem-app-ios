//
//  CommonExpressBalanceProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
import TangemExpress

@Suite("CommonExpressBalanceProvider")
struct CommonExpressBalanceProviderTests {
    @Test("noAccount balance is treated as zero")
    func noAccountBalanceIsZero() throws {
        let provider = makeProvider(balanceType: .empty(.noAccount(message: "Account is not created")))

        #expect(try provider.getBalance() == 0)
        #expect(try provider.getCoinBalance() == 0)
    }

    @Test("Genuinely unknown balances still throw")
    func unknownBalanceThrows() {
        let unknownStates: [TokenBalanceType] = [
            .empty(.noData),
            .loading(nil),
            .failure(nil),
        ]

        for state in unknownStates {
            let provider = makeProvider(balanceType: state)

            #expect(throws: ExpressBalanceProviderError.balanceNotFound) {
                try provider.getBalance()
            }
            #expect(throws: ExpressBalanceProviderError.balanceNotFound) {
                try provider.getCoinBalance()
            }
        }
    }

    @Test("Loaded and cached balances are returned as is")
    func knownBalanceIsReturned() throws {
        let loaded = makeProvider(balanceType: .loaded(42))
        #expect(try loaded.getBalance() == 42)
        #expect(try loaded.getCoinBalance() == 42)

        let cached = makeProvider(balanceType: .loading(.init(balance: 7, date: .distantPast)))
        #expect(try cached.getBalance() == 7)
        #expect(try cached.getCoinBalance() == 7)
    }

    // MARK: - Helpers

    private func makeProvider(balanceType: TokenBalanceType) -> CommonExpressBalanceProvider {
        CommonExpressBalanceProvider(
            availableBalanceProvider: MutableTokenBalanceProviderMock(initialState: balanceType),
            feeBalanceProvider: MutableTokenBalanceProviderMock(initialState: balanceType)
        )
    }
}
