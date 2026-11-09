//
//  PolymarketOrderQuoteLoopTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket order quote loop", .timeLimit(.minutes(1)))
struct PolymarketOrderQuoteLoopTests {
    @Test("An order nobody holds is released while it polls the book price")
    func modelPollingTheBookPriceIsReleased() async throws {
        let delays = PolymarketSteppedDelayProvider()
        weak var released: PolymarketOrderModel?

        do {
            let model = await makeModel(delays: delays)
            model.handleViewAction(.onAppear)
            try await delays.waitUntilParked(Self.pollInterval)
            released = model
        }

        try await delays.cancellations.next()

        #expect(released == nil)
        #expect(delays.parkedWaits.isEmpty)
    }

    @Test("An order nobody holds is released while it polls the quote for the entered amount")
    func modelPollingTheQuoteIsReleased() async throws {
        let delays = PolymarketSteppedDelayProvider()
        let api = PolymarketAPIProviderStub(quoteResult: .stub(status: .full))
        weak var released: PolymarketOrderModel?

        do {
            let model = await makeModel(delays: delays, api: api)
            model.handleViewAction(.onAppear)
            try await delays.waitUntilParked(Self.pollInterval)

            model.handleViewAction(.selectFraction(.half))
            try await delays.cancellations.next()
            try await api.quoteRequested.next()
            try await delays.waitUntilParked(Self.pollInterval)
            released = model
        }

        try await delays.cancellations.next()

        #expect(released == nil)
        #expect(delays.parkedWaits.isEmpty)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderQuoteLoopTests {
    static let pollInterval: TimeInterval = 3

    func makeModel(
        delays: PolymarketSteppedDelayProvider,
        api: PolymarketAPIProviderStub = PolymarketAPIProviderStub()
    ) async -> PolymarketOrderModel {
        let balance: Decimal = 200
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: .buy(balance: .just(output: balance)),
            apiProvider: api,
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: balance),
            addFundsReadinessStream: AsyncStream { $0.yield(.unavailable); $0.finish() },
            delayProvider: delays
        )

        _ = await model.$state.firstValue { $0.balance != nil }

        return model
    }
}
