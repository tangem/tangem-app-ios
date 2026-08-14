//
//  TokenBalanceTypeTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TokenBalanceType.mayHaveFunds")
struct TokenBalanceTypeMayHaveFundsTests {
    private let date = Date(timeIntervalSince1970: 0)

    @Test("A loaded zero (or negative) balance has no funds")
    func loadedZeroHasNoFunds() {
        #expect(!TokenBalanceType.loaded(0).mayHaveFunds)
        #expect(!TokenBalanceType.loaded(-1).mayHaveFunds)
    }

    @Test("A loaded positive balance has funds")
    func loadedPositiveHasFunds() {
        #expect(TokenBalanceType.loaded(0.5).mayHaveFunds)
        #expect(TokenBalanceType.loaded(100).mayHaveFunds)
    }

    @Test("An unknown balance may still have funds")
    func unknownMayHaveFunds() {
        #expect(TokenBalanceType.empty(.noData).mayHaveFunds)
        #expect(TokenBalanceType.empty(.noDerivation).mayHaveFunds)
        #expect(TokenBalanceType.loading(nil).mayHaveFunds)
        #expect(TokenBalanceType.failure(nil).mayHaveFunds)
    }

    @Test("A noAccount balance (unfunded XLM/XRP-like wallet) has no funds")
    func noAccountHasNoFunds() {
        #expect(!TokenBalanceType.empty(.noAccount(message: "")).mayHaveFunds)
    }

    @Test("A cached balance during loading/failure follows the cached value")
    func cachedFollowsCachedValue() {
        #expect(!TokenBalanceType.loading(.init(balance: 0, date: date)).mayHaveFunds)
        #expect(TokenBalanceType.loading(.init(balance: 3, date: date)).mayHaveFunds)
        #expect(!TokenBalanceType.failure(.init(balance: 0, date: date)).mayHaveFunds)
        #expect(TokenBalanceType.failure(.init(balance: 2, date: date)).mayHaveFunds)
    }
}
