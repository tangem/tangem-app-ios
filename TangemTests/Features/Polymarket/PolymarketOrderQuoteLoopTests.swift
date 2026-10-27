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
@Suite("Polymarket order quote loop")
struct PolymarketOrderQuoteLoopTests {
    @Test("An order nobody holds is released while it polls the book price")
    func modelPollingTheBookPriceIsReleased() async throws {
        weak var released: PolymarketOrderModel?

        do {
            let model = try await makeModel()
            model.handleViewAction(.onAppear)
            try await drain()
            released = model
        }

        try await settle { released == nil }
    }

    @Test("An order nobody holds is released while it polls the quote for the entered amount")
    func modelPollingTheQuoteIsReleased() async throws {
        weak var released: PolymarketOrderModel?

        do {
            let model = try await makeModel()
            model.handleViewAction(.onAppear)
            model.handleViewAction(.selectFraction(.half))
            try await drain()
            released = model
        }

        try await settle { released == nil }
    }
}

// MARK: - Fixtures

private extension PolymarketOrderQuoteLoopTests {
    func makeModel() async throws -> PolymarketOrderModel {
        let balance: Decimal = 200
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: .buy(balance: .just(output: balance)),
            apiProvider: PolymarketAPIProviderStub(quoteResult: .stub(status: .full)),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: balance),
            addFundsReadinessStream: AsyncStream { $0.yield(.unavailable); $0.finish() }
        )

        try await settle { model.state.balance != nil }

        return model
    }
}
