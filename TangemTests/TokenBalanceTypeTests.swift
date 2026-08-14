//
//  TokenBalanceTypeTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TokenBalanceType.hasNoFunds")
struct TokenBalanceTypeHasNoFundsTests {
    private let date = Date(timeIntervalSince1970: 0)

    @Test("A loaded zero (or negative) balance has no funds")
    func loadedZeroHasNoFunds() {
        #expect(TokenBalanceType.loaded(0).hasNoFunds)
        #expect(TokenBalanceType.loaded(-1).hasNoFunds)
    }

    @Test("A loaded positive balance has funds")
    func loadedPositiveHasFunds() {
        #expect(!TokenBalanceType.loaded(0.5).hasNoFunds)
        #expect(!TokenBalanceType.loaded(100).hasNoFunds)
    }

    @Test("An unknown balance is never treated as having no funds")
    func unknownIsNotTreatedAsNoFunds() {
        #expect(!TokenBalanceType.empty(.noData).hasNoFunds)
        #expect(!TokenBalanceType.empty(.noDerivation).hasNoFunds)
        #expect(!TokenBalanceType.loading(nil).hasNoFunds)
        #expect(!TokenBalanceType.failure(nil).hasNoFunds)
    }

    @Test("A noAccount balance (unfunded XLM/XRP-like wallet) has no funds")
    func noAccountHasNoFunds() {
        #expect(TokenBalanceType.empty(.noAccount(message: "")).hasNoFunds)
    }

    @Test("A cached balance during loading/failure follows the cached value")
    func cachedFollowsCachedValue() {
        #expect(TokenBalanceType.loading(.init(balance: 0, date: date)).hasNoFunds)
        #expect(!TokenBalanceType.loading(.init(balance: 3, date: date)).hasNoFunds)
        #expect(TokenBalanceType.failure(.init(balance: 0, date: date)).hasNoFunds)
        #expect(!TokenBalanceType.failure(.init(balance: 2, date: date)).hasNoFunds)
    }
}
