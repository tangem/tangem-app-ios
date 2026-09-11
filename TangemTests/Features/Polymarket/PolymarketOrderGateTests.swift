//
//  PolymarketOrderGateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@MainActor
@Suite("Polymarket order gate")
struct PolymarketOrderGateTests {
    @Test("A quote the exchange can fill lets the flow move on")
    func placeableQuoteOpensTheButton() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .full)))

        #expect(gate.isPrimaryButtonEnabled)
        #expect(gate.notifications.isEmpty)
    }

    @Test("A partial fill warns without standing in the way")
    func partialQuoteWarnsButPasses() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .partial)))

        #expect(gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.partialFill])
    }

    @Test(
        "An order under the exchange floor never reaches the next screen",
        arguments: [PolymarketQuoteStatus.belowMinOrderSize, .belowMinOrderAmount]
    )
    func belowTheFloorClosesTheButton(status: PolymarketQuoteStatus) {
        let floor = Decimal(string: "4.5")!
        let quote = PolymarketOrderQuote.stub(status: status)
        let state = PolymarketOrderModel.State.stub(
            quote: quote,
            enteredAmount: Decimal(string: "0.5")!,
            minAmount: floor
        )

        let gate = PolymarketOrderGate(state: state)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == .belowMinAmount(floor))
    }

    @Test("Until the floor is known the banner carries the refusal instead of the caption")
    func belowTheFloorWithoutAKnownMinimumBanners() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .belowMinOrderSize)))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.belowMinOrder])
    }

    @Test("A market that stopped taking orders blocks the flow")
    func closedMarketBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .unavailable(.marketClosed)))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.marketClosed])
    }

    @Test("An empty book blocks the flow and says why")
    func emptyBookBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .unavailable(.insufficientLiquidity)))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.noLiquidity])
    }

    @Test("A status this build cannot read is offered as a retry, not as a verdict")
    func undefinedStatusBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .unavailable(.undefined)))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.quoteUnavailable])
    }

    @Test("A quote that never arrived offers a retry and holds the button")
    func failedQuoteBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .failed(.network)))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.quoteUnavailable])
    }

    @Test("Waiting for the first quote is not a reason to warn, only to wait")
    func loadingIsSilent() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .loading))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications.isEmpty)
        #expect(gate.amountCaption == nil)
    }

    @Test("A bet larger than the balance is refused before the fees are even counted")
    func balanceShortfallBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .full), enteredAmount: 200, balance: 100))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == .notEnoughForBet)
    }

    @Test("A bet the balance covers but the fees do not is refused too")
    func feeShortfallBlocks() {
        let quote = PolymarketOrderQuote.stub(status: .full, total: Decimal(string: "100.5")!)
        let gate = PolymarketOrderGate(state: .stub(quote: quote, enteredAmount: 100, balance: 100))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == .notEnoughForFees)
    }

    @Test("A restricted region stops the order however good the quote is")
    func blockedRegionStops() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .full), geoblock: .blocked))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.regionRestricted])
    }

    @Test("An unresolved region is not treated as permission")
    func unknownRegionStops() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .full), geoblock: .unknown))

        #expect(!gate.isPrimaryButtonEnabled)
    }

    @Test("The caption states what the bet wins once nothing else is wrong")
    func captionShowsTheWin() {
        let quote = PolymarketOrderQuote.stub(status: .full, shares: 138, expectedExecutionAmount: 140)
        let gate = PolymarketOrderGate(state: .stub(quote: quote))

        #expect(gate.amountCaption == .toWin(expected: 140, guaranteed: 138))
    }
}

// MARK: - Fixtures

extension PolymarketOrderModel.State {
    static func stub(
        quoteState: PolymarketOrderQuoteState = .empty,
        enteredAmount: Decimal? = 100,
        minAmount: Decimal? = nil,
        balance: Decimal? = 30000,
        geoblock: PolymarketGeoblockState = .allowed
    ) -> PolymarketOrderModel.State {
        var state = PolymarketOrderModel.State()
        state.quote = quoteState
        state.enteredAmount = enteredAmount
        state.minAmount = minAmount
        state.balance = balance
        state.geoblock = geoblock

        return state
    }

    static func stub(
        quote: PolymarketOrderQuote,
        enteredAmount: Decimal? = 100,
        minAmount: Decimal? = nil,
        balance: Decimal? = 30000,
        geoblock: PolymarketGeoblockState = .allowed
    ) -> PolymarketOrderModel.State {
        stub(
            quoteState: PolymarketOrderQuoteState(quote: quote),
            enteredAmount: enteredAmount,
            minAmount: minAmount,
            balance: balance,
            geoblock: geoblock
        )
    }
}

extension PolymarketOrderQuote {
    static func stub(
        status: PolymarketQuoteStatus,
        shares: Decimal = 138,
        expectedExecutionAmount: Decimal = 140,
        total: Decimal = Decimal(string: "100.5")!,
        isLive: Bool = false
    ) -> PolymarketOrderQuote {
        PolymarketOrderQuote(
            status: status,
            side: .buy,
            shares: shares,
            notional: 100,
            expectedExecutionAmount: expectedExecutionAmount,
            averagePrice: Decimal(string: "0.72")!,
            worstCasePrice: Decimal(string: "0.735")!,
            fees: PolymarketOrderFees(
                market: Decimal(string: "0.3")!,
                builder: Decimal(string: "0.2")!,
                total: Decimal(string: "0.5")!
            ),
            total: total,
            builderCode: "0x00000000000000000000000000000000000000000000000000000000000000aa",
            minOrderSize: 5,
            minOrderAmount: 1,
            tickSize: Decimal(string: "0.001")!,
            isLive: isLive
        )
    }
}
