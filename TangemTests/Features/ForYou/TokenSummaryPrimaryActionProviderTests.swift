//
//  TokenSummaryPrimaryActionProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

// MARK: - isFunded mapping

@Suite("TokenBalanceProvider.isFunded")
struct TokenBalanceProviderFundedTests {
    @Test("A positive available balance — loaded, or cached under loading/failure — is funded")
    func fundedStates() {
        let positiveCache = TokenBalanceType.Cached(balance: 100, date: .distantPast)

        expectFunded(.loaded(100), true)
        expectFunded(.loading(positiveCache), true)
        expectFunded(.failure(positiveCache), true)
    }

    @Test("Zero, negative and unknown balances are not funded")
    func notFundedStates() {
        // Unknown balances (no value) intentionally coalesce to not-funded.
        expectFunded(.loaded(0), false)
        expectFunded(.loaded(-1), false)
        expectFunded(.empty(.noData), false)
        expectFunded(.loading(nil), false)
        expectFunded(.failure(nil), false)
    }
}

// MARK: - isFunded assertions

private extension TokenBalanceProviderFundedTests {
    func expectFunded(
        _ state: TokenBalanceType,
        _ expected: Bool,
        sourceLocation: SourceLocation = .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column)
    ) {
        let isFunded = MutableTokenBalanceProviderMock(initialState: state).isFunded
        #expect(isFunded == expected, sourceLocation: sourceLocation)
    }
}

// MARK: - Primary action publisher

@Suite("TokenSummaryPrimaryActionProvider")
struct TokenSummaryPrimaryActionProviderTests {
    typealias SUT = TokenSummaryPrimaryActionProvider

    @Test("Without balance providers there is no primary action")
    func noProviders() {
        expectActions(from: [], equal: [nil])
    }

    @Test("A funded holding routes to Swap; a non-funded one to Add Funds")
    func routesBySingleHolding() {
        expectActions(from: [provider(.loaded(100))], equal: [.goToSwap(isEnabled: true)])
        expectActions(from: [provider(.loaded(0))], equal: [.addFunds])
    }

    @Test("Any funded holding wins over non-funded ones")
    func anyFundedWins() {
        expectActions(from: [provider(.loaded(0)), provider(.loaded(50))], equal: [.goToSwap(isEnabled: true)])
    }

    @Test("The action recomputes when a balance turns positive")
    func recomputesOnBalanceChange() {
        let holding = provider(.loaded(0))

        expectActions(from: [holding], equal: [.addFunds, .goToSwap(isEnabled: true)]) {
            holding.updateBalance(.loaded(100))
        }
    }

    @Test("A repeated identical balance does not re-emit the same action")
    func deduplicatesIdenticalActions() {
        let holding = provider(.loaded(100))

        expectActions(from: [holding], equal: [.goToSwap(isEnabled: true)]) {
            holding.sendUpdate()
        }
    }
}

// MARK: - Primary action assertions & fixtures

private extension TokenSummaryPrimaryActionProviderTests {
    /// Collects everything the action publisher emits (seed + reactions to `whenReady`) and matches it against `expected`.
    /// The pipeline is fully synchronous, so the emissions are all in by the time the expectation runs.
    func expectActions(
        from providers: [any TokenBalanceProvider],
        equal expected: [TokenSummaryPrimaryAction?],
        sourceLocation: SourceLocation = .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column),
        whenReady mutate: () -> Void = {}
    ) {
        var received: [TokenSummaryPrimaryAction?] = []
        let cancellable = SUT.makePublisher(balanceProviders: providers).sink { received.append($0) }
        defer { cancellable.cancel() }

        mutate()

        #expect(received == expected, sourceLocation: sourceLocation)
    }

    func provider(_ state: TokenBalanceType) -> MutableTokenBalanceProviderMock {
        MutableTokenBalanceProviderMock(initialState: state)
    }
}
