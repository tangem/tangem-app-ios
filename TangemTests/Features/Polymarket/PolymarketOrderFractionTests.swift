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

        model.handleViewAction(.selectFraction(.half))

        #expect(model.state.enteredAmount == 100)
        #expect(model.amountField.value == 100)
    }

    @Test("A share of the balance is cut to the cent the field can spell")
    func fractionIsRoundedToTheEnterablePrecision() async throws {
        let model = try await makeModel(balance: Decimal(string: "0.3333333")!)

        model.handleViewAction(.selectFraction(.quarter))

        #expect(model.state.enteredAmount == Decimal(string: "0.08")!)
    }

    @Test("Max buys with nine tenths of the balance and leaves the rest untouched")
    func maxIsNineTenthsOfTheBalance() async throws {
        let model = try await makeModel(balance: 201, quote: .stub(status: .full))

        model.handleViewAction(.onAppear)
        model.handleViewAction(.selectFraction(.quarter))

        try await settle { model.state.quote.quote != nil }

        model.handleViewAction(.selectFraction(.max))

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

        model.handleViewAction(.onAppear)
        model.handleViewAction(.selectFraction(.quarter))

        try await settle { model.state.quote.quote != nil }

        model.handleViewAction(.selectFraction(.max))

        #expect(model.state.enteredAmount == 100)
    }

    @Test("The nine tenths Max offers are cut to the cent the field can spell")
    func maxIsRoundedToTheEnteredPrecision() async throws {
        let model = try await makeModel(balance: Decimal(string: "0.3333333")!)

        model.handleViewAction(.selectFraction(.max))

        #expect(model.state.enteredAmount == Decimal(string: "0.29")!)
    }

    @Test("A share of a position is cut to whole tokens")
    func sellFractionIsCutToWholeTokens() async throws {
        let held = Decimal(string: "23.8")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        model.handleViewAction(.selectFraction(.half))

        #expect(model.state.enteredAmount == 11)
    }

    @Test("Max on a position offers everything it holds, fraction of a token included")
    func sellMaxIsTheWholeHolding() async throws {
        let held = Decimal(string: "23.8")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        model.handleViewAction(.selectFraction(.max))

        #expect(model.state.enteredAmount == held)
    }

    @Test("A position smaller than a token is sold whole")
    func sellMaxOfATinyPositionIsExact() async throws {
        let held = Decimal(string: "0.4")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        model.handleViewAction(.selectFraction(.max))

        #expect(model.state.enteredAmount == held)
    }

    @Test("Without a quote to read the fee from, Max still offers nine tenths of the balance")
    func maxWithoutAQuoteIsNineTenthsOfTheBalance() async throws {
        let model = try await makeModel(balance: 200)

        model.handleViewAction(.selectFraction(.max))

        #expect(model.state.enteredAmount == 180)
    }

    @Test("A share too small to quote leaves the order without an amount")
    func aShareBelowTheFloorIsNotQuoted() async throws {
        let model = try await makeModel(balance: Decimal(string: "0.02")!)

        model.handleViewAction(.selectFraction(.quarter))

        #expect(model.state.enteredAmount == nil)
        #expect(model.amountField.value == 0)
    }
}

// MARK: - Stepper bounds

@MainActor
@Suite("Polymarket amount steppers")
struct PolymarketOrderStepperTests {
    @Test("A sale opens on the whole position, so only the minus can move")
    func saleOpensAtTheTop() async throws {
        let model = try await makeModel(balance: 10, intent: .sell(shares: 10))

        #expect(model.state.enteredAmount == 10)
        #expect(!model.gate.canStepUp)
        #expect(model.gate.canStepDown)
    }

    @Test("A step moves by one token and keeps the fractional tail")
    func stepKeepsTheFractionalTail() async throws {
        let held = Decimal(string: "5.5")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        model.handleViewAction(.step(-1))

        #expect(model.state.enteredAmount == Decimal(string: "4.5")!)
    }

    @Test("The minus stops at one token, never in between")
    func minusStopsAtOneToken() async throws {
        let held = Decimal(string: "5.5")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        for _ in 0 ..< 5 {
            model.handleViewAction(.step(-1))
        }

        #expect(model.state.enteredAmount == 1)
        #expect(!model.gate.canStepDown)
        #expect(model.gate.canStepUp)
    }

    @Test("The plus climbs in whole tokens and lands on the whole position")
    func plusClimbsToTheWholePosition() async throws {
        let held = Decimal(string: "5.5")!
        let model = try await makeModel(balance: held, intent: .sell(shares: held))

        for _ in 0 ..< 5 {
            model.handleViewAction(.step(-1))
        }

        model.handleViewAction(.step(1))
        #expect(model.state.enteredAmount == 2)

        for _ in 0 ..< 4 {
            model.handleViewAction(.step(1))
        }

        #expect(model.state.enteredAmount == held)
        #expect(!model.gate.canStepUp)
    }

    @Test("A position smaller than a token cannot be stepped at all")
    func dustPositionHasNoSteps() async throws {
        let dust = Decimal(string: "0.4")!
        let model = try await makeModel(balance: dust, intent: .sell(shares: dust))

        #expect(model.state.enteredAmount == dust)
        #expect(!model.gate.canStepUp)
        #expect(!model.gate.canStepDown)
    }

    @Test("A purchase with an empty field can only step up")
    func purchaseStartsEmpty() async throws {
        let model = try await makeModel(balance: 200)

        #expect(model.state.enteredAmount == nil)
        #expect(model.gate.canStepUp)
        #expect(!model.gate.canStepDown)
    }

    @Test("Without a balance neither stepper is offered")
    func noBalanceOffersNoSteps() {
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: .buy(balance: .just(output: nil)),
            apiProvider: PolymarketAPIProviderStub(),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: nil)
        )

        #expect(!model.gate.canStepUp)
        #expect(!model.gate.canStepDown)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderStepperTests {
    func makeModel(
        balance: Decimal,
        intent: PolymarketOrderIntent? = nil
    ) async throws -> PolymarketOrderModel {
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: intent ?? .buy(balance: .just(output: balance)),
            apiProvider: PolymarketAPIProviderStub(),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: balance)
        )

        try await settle { model.state.balance != nil }

        return model
    }

    func settle(until isSatisfied: () -> Bool) async throws {
        for _ in 0 ..< 100 {
            if isSatisfied() {
                return
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        Issue.record("The model did not settle in time")
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
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: balance)
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

// MARK: - Fixtures

private extension PolymarketOrderModel {
    var gate: PolymarketOrderGate {
        PolymarketOrderGate(state: state, intent: intent)
    }
}

private extension PolymarketOrderGate {
    func isFractionSelectable(_ fraction: PolymarketAmountFraction) -> Bool {
        selectableFractions.contains(fraction)
    }
}
