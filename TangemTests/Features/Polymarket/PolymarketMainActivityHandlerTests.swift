//
//  PolymarketMainActivityHandlerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket main activity handler")
@MainActor
struct PolymarketMainActivityHandlerTests {
    @Test("An order expects a balance change, refreshes the balance before and after indexing, then hands over the traded position")
    func orderRefreshesBalanceAroundIndexing() async throws {
        let context = Self.makeSUT()
        let traded = PositionLog()

        let indexing = IndexingGate()

        context.handler.setTradedHandler { traded.positions.append($0?.conditionId) }
        context.handler.orderPlaced(awaiting: Task { await indexing.wait() })

        #expect(context.tracker.isBalanceChangeExpected)

        try await settle { context.scopes.entries == [.balance] }
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(context.scopes.entries == [.balance])
        #expect(traded.positions.isEmpty)

        indexing.open()

        try await settle { traded.positions.count == 1 }
        #expect(context.scopes.entries == [.balance, .balance])
    }

    @Test("A claim expects a balance change, refreshes the balance once, then hands over the claimed position")
    func claimRefreshesBalanceOnce() async throws {
        let context = Self.makeSUT()
        let claimed = PositionLog()

        context.handler.setClaimedHandler { claimed.positions.append($0?.conditionId) }
        context.handler.claimed(nil)

        #expect(context.tracker.isBalanceChangeExpected)

        try await settle { claimed.positions.count == 1 }

        #expect(context.scopes.entries == [.balance])
    }
}

// MARK: - Helpers

private extension PolymarketMainActivityHandlerTests {
    struct Context {
        let handler: PolymarketMainActivityHandler
        let tracker: PolymarketFundsArrivalTracker
        let scopes: ScopeLog
    }

    static func makeSUT() -> Context {
        let refreshCenter = PolymarketMainRefreshCenter()
        let tracker = PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher())
        let scopes = ScopeLog()

        refreshCenter.register { scopes.entries.append($0) }

        return Context(
            handler: PolymarketMainActivityHandler(fundsArrivalTracker: tracker, refreshCenter: refreshCenter),
            tracker: tracker,
            scopes: scopes
        )
    }
}

// MARK: - Doubles

@MainActor
private final class ScopeLog {
    var entries: [PolymarketMainRefreshCenter.Scope] = []
}

private final class IndexingGate {
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        var continuation: AsyncStream<Void>.Continuation?
        stream = AsyncStream { continuation = $0 }
        self.continuation = continuation!
    }

    func wait() async -> PolymarketPosition? {
        for await _ in stream {
            break
        }

        return nil
    }

    func open() {
        continuation.yield()
        continuation.finish()
    }
}

@MainActor
private final class PositionLog {
    var positions: [String?] = []
}
