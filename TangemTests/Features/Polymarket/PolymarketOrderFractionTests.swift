//
//  PolymarketOrderFractionTests.swift
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
@Suite("Polymarket amount fractions")
struct PolymarketOrderFractionTests {
    @Test("A chip moves the amount the order is quoted at, not just the digits in the field")
    func chipMovesTheOrder() async throws {
        let model = try await makeModel(balance: 200)

        model.handleViewAction(.fractionSelected(.half))

        #expect(model.state.enteredAmount == 100)
        #expect(model.amountField.value == 100)
    }

    @Test("A share of the balance is cut to what the collateral can express")
    func fractionIsRoundedToCollateralPrecision() async throws {
        let model = try await makeModel(balance: Decimal(string: "0.3333333")!)

        model.handleViewAction(.fractionSelected(.quarter))

        #expect(model.state.enteredAmount == Decimal(string: "0.083333")!)
    }

    @Test("Max leaves room for the fee the exchange adds on top")
    func maxLeavesRoomForTheFee() async throws {
        // The quote reports half a point of fee: 0.5 charged on a notional of 100.
        let model = try await makeModel(balance: 201, quote: .stub(status: .full))

        model.handleViewAction(.screenAppeared)
        model.handleViewAction(.fractionSelected(.quarter))

        try await settle { model.state.quote.quote != nil }

        model.handleViewAction(.fractionSelected(.max))

        #expect(model.state.enteredAmount == 200)
    }

    @Test("Without a quote to read the fee from, Max still offers the whole balance")
    func maxWithoutAQuoteIsTheWholeBalance() async throws {
        let model = try await makeModel(balance: 200)

        model.handleViewAction(.fractionSelected(.max))

        #expect(model.state.enteredAmount == 200)
    }

    @Test("A share too small to quote leaves the order without an amount")
    func aShareBelowTheFloorIsNotQuoted() async throws {
        let model = try await makeModel(balance: Decimal(string: "0.02")!)

        model.handleViewAction(.fractionSelected(.quarter))

        #expect(model.state.enteredAmount == nil)
        #expect(model.amountField.value == Decimal(string: "0.005")!)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderFractionTests {
    func makeModel(balance: Decimal, quote: PolymarketOrderQuote? = nil) async throws -> PolymarketOrderModel {
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            apiProvider: PolymarketAPIProviderStub(quoteResult: quote),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            balancePublisher: .just(output: balance)
        )

        try await settle { model.state.balance != nil }

        return model
    }

    func settle(until isSatisfied: () -> Bool) async throws {
        for _ in 0 ..< 200 {
            if isSatisfied() { return }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        Issue.record("The order model never settled")
    }
}

private extension PolymarketOutcome {
    static let fixture = PolymarketOutcome(assetId: "asset", title: "Yes", probability: Decimal(string: "0.55")!)
}

private extension PolymarketMarket {
    static let fixture = PolymarketMarket(
        id: "market",
        conditionId: nil,
        title: "Will Uzbekistan win the 2026 FIFA World Cup?",
        groupItemTitle: nil,
        imageURL: nil,
        iconURL: nil,
        status: .active,
        isNegRisk: false,
        isAcceptingOrders: true,
        startDate: nil,
        endDate: nil,
        volume: nil,
        volume24h: nil,
        liquidity: nil,
        orderIndex: nil,
        outcomes: [.fixture]
    )
}
