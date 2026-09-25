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
    static let buyIntent = PolymarketOrderIntent.buy(balance: .just(output: nil))

    @Test("A quote the exchange can fill lets the flow move on")
    func placeableQuoteOpensTheButton() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .full)), intent: Self.buyIntent)

        #expect(gate.isPrimaryButtonEnabled)
        #expect(gate.notifications.isEmpty)
    }

    @Test("A partial fill warns without standing in the way")
    func partialQuoteWarnsButPasses() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .partial)), intent: Self.buyIntent)

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

        let gate = PolymarketOrderGate(state: state, intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == .belowMinAmount(floor))
    }

    @Test("Until the floor is known the banner carries the refusal instead of the caption")
    func belowTheFloorWithoutAKnownMinimumBanners() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .belowMinOrderSize)), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.belowMinOrder])
    }

    @Test("A market that stopped taking orders blocks the flow")
    func closedMarketBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .unavailable(.marketClosed)), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.marketClosed])
    }

    @Test("An empty book blocks the flow and says why")
    func emptyBookBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .unavailable(.insufficientLiquidity)), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.noLiquidity])
    }

    @Test("A status this build cannot read is offered as a retry, not as a verdict")
    func undefinedStatusBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .unavailable(.undefined)), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.quoteUnavailable])
    }

    @Test("A quote that never arrived says so on the screen and holds the button")
    func failedQuoteBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .failed(.network)), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.quoteUnavailable])
    }

    @Test("Waiting for the first quote is not a reason to warn, only to wait")
    func loadingIsSilent() {
        let gate = PolymarketOrderGate(state: .stub(quoteState: .loading), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications.isEmpty)
        #expect(gate.amountCaption == nil)
    }

    @Test("A bet larger than the balance is refused before the fees are even counted")
    func balanceShortfallBlocks() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .full), enteredAmount: 200, balance: 100), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == .notEnoughForBet)
    }

    @Test("A bet the balance covers but the fees do not is refused too")
    func feeShortfallBlocks() {
        let quote = PolymarketOrderQuote.stub(status: .full, total: Decimal(string: "100.5")!)
        let gate = PolymarketOrderGate(state: .stub(quote: quote, enteredAmount: 100, balance: 100), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == .notEnoughForFees)
    }

    // MARK: - Selling

    @Test("Selling more shares than the position holds is refused")
    func sellOverTheHeldSizeBlocks() {
        let state = PolymarketOrderModel.State.stub(quote: .stub(status: .full), enteredAmount: 1001, balance: 1000)
        let gate = PolymarketOrderGate(state: state, intent: .sell(shares: 1000))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == .notEnoughForBet)
    }

    @Test("Selling the whole position is allowed")
    func sellOfTheWholePositionPasses() {
        let state = PolymarketOrderModel.State.stub(quote: .stub(status: .full), enteredAmount: 1000, balance: 1000)
        let gate = PolymarketOrderGate(state: state, intent: .sell(shares: 1000))

        #expect(gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == nil)
    }

    @Test("A sell is measured in shares, so the collateral the fees need never enters the comparison")
    func sellIgnoresTheFeeShortfall() {
        let quote = PolymarketOrderQuote.stub(status: .full, total: 5000)
        let state = PolymarketOrderModel.State.stub(quote: quote, enteredAmount: 1000, balance: 1000)
        let gate = PolymarketOrderGate(state: state, intent: .sell(shares: 1000))

        #expect(gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption != .notEnoughForFees)
    }

    @Test("A sell says nothing about winnings — the proceeds live on the confirmation")
    func sellHasNoWinCaption() {
        let state = PolymarketOrderModel.State.stub(quote: .stub(status: .full), enteredAmount: 10, balance: 1000)
        let gate = PolymarketOrderGate(state: state, intent: .sell(shares: 1000))

        #expect(gate.amountCaption == nil)
    }

    @Test("A sell refused only for the taker's dollar floor is still a sell the exchange can fill")
    func sellIgnoresTheOrderAmountFloor() {
        let state = PolymarketOrderModel.State.stub(quote: .stub(status: .belowMinOrderAmount), enteredAmount: 10, balance: 1000)
        let gate = PolymarketOrderGate(state: state, intent: .sell(shares: 1000))

        #expect(gate.isPrimaryButtonEnabled)
        #expect(gate.notifications.isEmpty)
    }

    @Test("The backend's dollar-floor verdict is not a refusal on either side")
    func theOrderAmountFloorVerdictIsIgnored() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .belowMinOrderAmount)), intent: Self.buyIntent)

        #expect(gate.isPrimaryButtonEnabled)
        #expect(gate.notifications.isEmpty)
    }

    @Test("A buy the client itself puts under the floor is still refused")
    func buyUnderTheComputedFloorIsRefused() {
        let floor = Decimal(string: "4.5")!
        let state = PolymarketOrderModel.State.stub(
            quote: .stub(status: .belowMinOrderAmount),
            enteredAmount: Decimal(string: "0.5")!,
            minAmount: floor
        )

        let gate = PolymarketOrderGate(state: state, intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.amountCaption == .belowMinAmount(floor))
    }

    // MARK: - The floor each side answers to

    @Test("Buying floors at the dearer of the share minimum and the taker minimum")
    func buyFloorTakesTheLargerOfTheTwo() {
        let quote = PolymarketOrderQuote.stub(status: .full, minOrderSize: 5, minOrderAmount: 1)

        #expect(Self.buyIntent.minAmount(from: quote) == Decimal(string: "3.675")!)
    }

    @Test("Buying floors at the taker minimum when the shares are cheap enough to fall under it")
    func buyFloorFallsBackToTheTakerMinimum() {
        let quote = PolymarketOrderQuote.stub(status: .full, worstCasePrice: Decimal(string: "0.1")!, minOrderSize: 5, minOrderAmount: 1)

        #expect(Self.buyIntent.minAmount(from: quote) == 1)
    }

    @Test("Buying without a taker minimum floors at the share minimum alone")
    func buyFloorWithoutATakerMinimum() {
        let quote = PolymarketOrderQuote.stub(status: .full, minOrderSize: 5, minOrderAmount: nil)

        #expect(Self.buyIntent.minAmount(from: quote) == Decimal(string: "3.675")!)
    }

    @Test("Selling floors at one token, whatever the exchange asks for")
    func sellFloorsAtOneToken() {
        let quote = PolymarketOrderQuote.stub(status: .full, minOrderSize: 5, minOrderAmount: 1)

        #expect(PolymarketOrderIntent.sell(shares: 1000).minAmount(from: quote) == 1)
    }

    @Test("A position smaller than a token floors at everything it holds")
    func sellFloorsAtTheWholePositionWhenItIsTiny() {
        let quote = PolymarketOrderQuote.stub(status: .full, minOrderSize: 5, minOrderAmount: 1)
        let held = Decimal(string: "0.4")!

        #expect(PolymarketOrderIntent.sell(shares: held).minAmount(from: quote) == held)
    }

    @Test("An empty book on a sale is said under the amount, not in the notifications")
    func sellWithoutABookCaptionsTheAmount() {
        let state = PolymarketOrderModel.State.stub(quoteState: .unavailable(.insufficientLiquidity))
        let gate = PolymarketOrderGate(state: state, intent: .sell(shares: 1000))

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications.isEmpty)
        #expect(gate.amountCaption == .notEnoughLiquidity)
    }

    @Test("Selling under the share minimum keeps the order placeable and unwarned")
    func sellUnderTheShareMinimumStaysPlaceable() {
        let state = PolymarketOrderModel.State.stub(quote: .stub(status: .belowMinOrderSize), enteredAmount: 1, balance: 1000)
        let gate = PolymarketOrderGate(state: state, intent: .sell(shares: 1000))

        #expect(gate.isPrimaryButtonEnabled)
        #expect(gate.notifications.isEmpty)
    }

    @Test("A side with no floor to state reports none")
    func noFloorIsReportedAsNone() {
        let quote = PolymarketOrderQuote.stub(status: .full, minOrderSize: 0, minOrderAmount: nil)

        #expect(Self.buyIntent.minAmount(from: quote) == nil)
    }

    @Test("A restricted region stops the order however good the quote is")
    func blockedRegionStops() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .full), geoblock: .blocked), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
        #expect(gate.notifications == [.regionRestricted])
    }

    @Test("An unresolved region is not treated as permission")
    func unknownRegionStops() {
        let gate = PolymarketOrderGate(state: .stub(quote: .stub(status: .full), geoblock: .unknown), intent: Self.buyIntent)

        #expect(!gate.isPrimaryButtonEnabled)
    }

    @Test("The caption states what the bet wins once nothing else is wrong")
    func captionShowsTheWin() {
        let quote = PolymarketOrderQuote.stub(status: .full, shares: 138, expectedExecutionAmount: 140)
        let gate = PolymarketOrderGate(state: .stub(quote: quote), intent: Self.buyIntent)

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
        fees: PolymarketOrderFees = PolymarketOrderFees(
            market: Decimal(string: "0.3")!,
            builder: Decimal(string: "0.2")!,
            total: Decimal(string: "0.5")!
        ),
        total: Decimal = Decimal(string: "100.5")!,
        worstCasePrice: Decimal = Decimal(string: "0.735")!,
        minOrderSize: Decimal = 5,
        minOrderAmount: Decimal? = 1,
        isLive: Bool = false
    ) -> PolymarketOrderQuote {
        PolymarketOrderQuote(
            status: status,
            side: .buy,
            shares: shares,
            notional: 100,
            expectedExecutionAmount: expectedExecutionAmount,
            averagePrice: Decimal(string: "0.72")!,
            worstCasePrice: worstCasePrice,
            fees: fees,
            total: total,
            builderCode: "0x00000000000000000000000000000000000000000000000000000000000000aa",
            minOrderSize: minOrderSize,
            minOrderAmount: minOrderAmount,
            tickSize: Decimal(string: "0.001")!,
            isLive: isLive
        )
    }
}
