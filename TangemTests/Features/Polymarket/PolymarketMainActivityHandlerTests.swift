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

@Suite("Polymarket main activity handler", .timeLimit(.minutes(1)))
@MainActor
struct PolymarketMainActivityHandlerTests {
    @Test("An order expects a balance change, refreshes the balance before and after indexing, then hands over the traded position")
    func orderRefreshesBalanceAroundIndexing() async throws {
        let context = Self.makeSUT()
        let indexing = PolymarketTestGate()
        let log = context.log

        context.handler.setTradedHandler { log.send(.traded($0?.conditionId)) }
        context.handler.orderPlaced(awaiting: Task {
            await indexing.pass()
            log.send(.indexed)
            return Self.position
        })

        #expect(context.tracker.isBalanceChangeExpected)

        try await indexing.entered.next()
        try await log.next(where: { $0 == .refresh(.balance) })
        #expect(log.recorded == [.refresh(.balance)])

        indexing.open()

        try await log.next(where: { $0 == .traded(Self.position.conditionId) })
        #expect(log.recorded == [.refresh(.balance), .indexed, .refresh(.balance), .traded(Self.position.conditionId)])
    }

    @Test("A claim expects a balance change, refreshes the balance once, then hands over the claimed position")
    func claimRefreshesBalanceOnce() async throws {
        let context = Self.makeSUT()
        let log = context.log

        context.handler.setClaimedHandler { log.send(.claimed($0?.conditionId)) }
        context.handler.claimed(Self.position)

        #expect(context.tracker.isBalanceChangeExpected)

        try await log.next(where: { $0 == .claimed(Self.position.conditionId) })
        #expect(log.recorded == [.refresh(.balance), .claimed(Self.position.conditionId)])
    }
}

// MARK: - Helpers

private extension PolymarketMainActivityHandlerTests {
    struct Context {
        let handler: PolymarketMainActivityHandler
        let tracker: PolymarketFundsArrivalTracker
        let log: PolymarketTestSignal<ActivityEvent>
    }

    static func makeSUT() -> Context {
        let refreshCenter = PolymarketMainRefreshCenter()
        let tracker = PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher())
        let log = PolymarketTestSignal<ActivityEvent>()

        refreshCenter.register { log.send(.refresh($0)) }

        return Context(
            handler: PolymarketMainActivityHandler(fundsArrivalTracker: tracker, refreshCenter: refreshCenter),
            tracker: tracker,
            log: log
        )
    }

    static let position = PolymarketPosition(
        conditionId: "0x" + String(repeating: "a", count: 64),
        assetId: "7",
        marketId: "3",
        version: .v1,
        eventId: "4",
        eventTitle: "Event",
        title: "Question",
        iconURL: nil,
        endDate: nil,
        outcome: "Yes",
        outcomeIndex: 0,
        size: 1,
        avgPrice: 1,
        curPrice: 1,
        initialValue: 1,
        currentValue: 1,
        cashPnl: 0,
        pnlRatio: 0,
        realizedPnl: 0,
        isRedeemable: false,
        isNegRisk: false,
        isAcceptingOrders: true,
        isLive: false,
        resolutionStatus: .open,
        settlement: nil
    )
}

// MARK: - Doubles

private enum ActivityEvent: Equatable {
    case refresh(PolymarketMainRefreshCenter.Scope)
    case indexed
    case traded(String?)
    case claimed(String?)
}
