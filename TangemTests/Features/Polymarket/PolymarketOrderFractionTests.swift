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

    @Test("A share of the balance is cut to the cent the field can spell")
    func fractionIsRoundedToTheEnterablePrecision() async throws {
        let model = try await makeModel(balance: Decimal(string: "0.3333333")!)

        model.handleViewAction(.fractionSelected(.quarter))

        #expect(model.state.enteredAmount == Decimal(string: "0.08")!)
    }

    @Test("Max buys with nine tenths of the balance and leaves the rest untouched")
    func maxIsNineTenthsOfTheBalance() async throws {
        let model = try await makeModel(balance: 201, quote: .stub(status: .full))

        model.handleViewAction(.screenAppeared)
        model.handleViewAction(.fractionSelected(.quarter))

        try await settle { model.state.quote.quote != nil }

        model.handleViewAction(.fractionSelected(.max))

        #expect(model.state.enteredAmount == Decimal(string: "180.9")!)
    }

    @Test("A fee larger than the tenth Max holds back still caps what Max offers")
    func maxLeavesRoomForAnOversizedFee() async throws {
        let quote = PolymarketOrderQuote.stub(
            status: .full,
            fees: PolymarketOrderFees(market: 12, builder: 8, total: 20),
            total: 120
        )
        let model = try await makeModel(balance: 120, quote: quote)

        model.handleViewAction(.screenAppeared)
        model.handleViewAction(.fractionSelected(.quarter))

        try await settle { model.state.quote.quote != nil }

        model.handleViewAction(.fractionSelected(.max))

        #expect(model.state.enteredAmount == 100)
    }

    @Test("The nine tenths Max offers are cut to the cent the field can spell")
    func maxIsRoundedToTheEnteredPrecision() async throws {
        let model = try await makeModel(balance: Decimal(string: "0.3333333")!)

        model.handleViewAction(.fractionSelected(.max))

        #expect(model.state.enteredAmount == Decimal(string: "0.29")!)
    }

    @Test("A share of a position is cut to whole tokens")
    func sellFractionIsCutToWholeTokens() async throws {
        let held = Decimal(string: "23.8")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        model.handleViewAction(.fractionSelected(.half))

        #expect(model.state.enteredAmount == 11)
    }

    @Test("Max on a position offers everything it holds, fraction of a token included")
    func sellMaxIsTheWholeHolding() async throws {
        let held = Decimal(string: "23.8")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        model.handleViewAction(.fractionSelected(.max))

        #expect(model.state.enteredAmount == held)
    }

    @Test("A position smaller than a token is sold whole")
    func sellMaxOfATinyPositionIsExact() async throws {
        let held = Decimal(string: "0.4")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        model.handleViewAction(.fractionSelected(.max))

        #expect(model.state.enteredAmount == held)
    }

    @Test("Without a quote to read the fee from, Max still offers nine tenths of the balance")
    func maxWithoutAQuoteIsNineTenthsOfTheBalance() async throws {
        let model = try await makeModel(balance: 200)

        model.handleViewAction(.fractionSelected(.max))

        #expect(model.state.enteredAmount == 180)
    }

    @Test("A share too small to quote leaves the order without an amount")
    func aShareBelowTheFloorIsNotQuoted() async throws {
        let model = try await makeModel(balance: Decimal(string: "0.02")!)

        model.handleViewAction(.fractionSelected(.quarter))

        #expect(model.state.enteredAmount == nil)
        #expect(model.amountField.value == 0)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderFractionTests {
    func makeModel(
        balance: Decimal,
        quote: PolymarketOrderQuote? = nil,
        intent: PolymarketOrderIntent? = nil
    ) async throws -> PolymarketOrderModel {
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: intent ?? .buy(balance: .just(output: balance)),
            apiProvider: PolymarketAPIProviderStub(quoteResult: quote),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false)
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

extension PolymarketOutcome {
    static let fixture = PolymarketOutcome(assetId: "asset", title: "Yes", probability: Decimal(string: "0.55")!)
}

extension PolymarketMarket {
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
