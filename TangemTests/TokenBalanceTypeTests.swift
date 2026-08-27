//
//  TokenBalanceTypeTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TokenBalanceType.isZeroBalance")
struct TokenBalanceTypeIsZeroBalanceTests {
    private let date = Date(timeIntervalSince1970: 0)

    @Test("A loaded zero (or negative) balance is treated as zero")
    func loadedZeroIsZero() {
        #expect(TokenBalanceType.loaded(0).isZeroBalance)
        #expect(TokenBalanceType.loaded(-1).isZeroBalance)
    }

    @Test("A loaded positive balance is not zero")
    func loadedPositiveIsNotZero() {
        #expect(!TokenBalanceType.loaded(0.5).isZeroBalance)
        #expect(!TokenBalanceType.loaded(100).isZeroBalance)
    }

    @Test("An unknown balance is never treated as zero")
    func unknownIsNotZero() {
        #expect(!TokenBalanceType.empty(.noData).isZeroBalance)
        #expect(!TokenBalanceType.empty(.noDerivation).isZeroBalance)
        #expect(!TokenBalanceType.loading(nil).isZeroBalance)
        #expect(!TokenBalanceType.failure(nil).isZeroBalance)
    }

    @Test("A cached balance during loading/failure follows the cached value")
    func cachedFollowsCachedValue() {
        #expect(TokenBalanceType.loading(.init(balance: 0, date: date)).isZeroBalance)
        #expect(!TokenBalanceType.loading(.init(balance: 3, date: date)).isZeroBalance)
        #expect(TokenBalanceType.failure(.init(balance: 0, date: date)).isZeroBalance)
        #expect(!TokenBalanceType.failure(.init(balance: 2, date: date)).isZeroBalance)
    }
}
