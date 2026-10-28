//
//  PolymarketOrderQuoteHoldTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket quote held while the order is signed", .timeLimit(.minutes(1)))
struct PolymarketOrderQuoteHoldTests {
    @Test("Holding the quote stops the quote poll waiting for its next round")
    func holdStopsThePoll() async {
        let context = await makeContext()
        await context.quotePollParked()

        context.model.handleViewAction(.holdQuote)

        #expect(context.delayProvider.parkedCount == 0)
    }

    @Test("A retry while the quote is held neither requests a new quote nor replaces the held one")
    func retryKeepsHeldQuote() async {
        let context = await makeContext()
        let held = context.hold()

        context.model.handleViewAction(.retryQuote)

        held.expectUnchanged(in: context)
    }

    @Test("Amount, preset, step and slippage inputs while the quote is held change neither the amount nor the quote")
    func inputsKeepHeldQuote() async {
        let context = await makeContext()
        let held = context.hold()

        context.model.apply(enteredAmount: 250, debounced: false)
        context.model.handleViewAction(.selectAmount(300))
        context.model.handleViewAction(.selectFraction(.max))
        context.model.handleViewAction(.step(1))
        context.model.handleViewAction(.selectSlippage(5))

        held.expectUnchanged(in: context)
        #expect(context.model.amountField.value == held.fieldValue)
        #expect(context.model.state.slippagePercent == held.slippagePercent)
    }

    @Test("Coming back from background while the quote is held keeps the held quote")
    func foregroundKeepsHeldQuote() async {
        let context = await makeContext()
        let held = context.hold()

        context.appState.enterBackground()
        context.appState.enterForeground()

        held.expectUnchanged(in: context)
    }

    @Test("Releasing the held quote requests a fresh one")
    func releaseRestartsQuoting() async {
        let context = await makeContext()
        let held = context.hold()

        context.model.handleViewAction(.releaseQuote)
        await Self.state(of: context.model) { $0.quote.quote != nil }

        #expect(context.api.quoteRequests.count > held.requests)
    }

    @Test("Held shares arriving while the quote is held wait for the release")
    func heldSharesWaitForRelease() async {
        let context = await makeContext(sells: true)
        let held = context.hold()

        context.positions.open()
        _ = await context.model.awaitIndexing().value

        held.expectUnchanged(in: context)
        #expect(context.model.state.balance == Self.shares)

        context.model.handleViewAction(.releaseQuote)
        await Self.state(of: context.model) { $0.quote.quote != nil }

        #expect(context.api.quoteRequests.last?.amount == Self.arrivedShares)
        #expect(context.model.state.balance == Self.arrivedShares)
        #expect(context.model.state.enteredAmount == Self.arrivedShares)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderQuoteHoldTests {
    static let shares: Decimal = 10
    static let arrivedShares: Decimal = 6

    @MainActor
    struct Context {
        let model: PolymarketOrderModel
        let api: PolymarketAPIProviderStub
        let positions: HeldPositionServiceStub
        let appState: AppStateObserverStub
        let delayProvider: HoldingDelayProviderSpy

        func quotePollParked() async {
            for await _ in delayProvider.parks where delayProvider.parkedCount > 0 {
                return
            }
        }

        func hold() -> Held {
            model.handleViewAction(.holdQuote)

            return Held(
                quote: model.state.quote,
                enteredAmount: model.state.enteredAmount,
                fieldValue: model.amountField.value,
                slippagePercent: model.state.slippagePercent,
                requests: api.quoteRequests.count
            )
        }
    }

    @MainActor
    struct Held {
        let quote: PolymarketOrderQuoteState
        let enteredAmount: Decimal?
        let fieldValue: Decimal?
        let slippagePercent: Decimal
        let requests: Int

        func expectUnchanged(in context: Context, sourceLocation: SourceLocation = #_sourceLocation) {
            #expect(context.model.state.quote == quote, sourceLocation: sourceLocation)
            #expect(context.model.state.enteredAmount == enteredAmount, sourceLocation: sourceLocation)
            #expect(context.api.quoteRequests.count == requests, sourceLocation: sourceLocation)
        }
    }

    func makeContext(sells: Bool = false) async -> Context {
        let api = PolymarketAPIProviderStub(quoteResult: .stub(status: .full))
        let positions = HeldPositionServiceStub(size: Self.arrivedShares, isOpen: !sells)
        let appState = AppStateObserverStub()
        let delayProvider = HoldingDelayProviderSpy(holdThreshold: 1)

        let model = PolymarketOrderModel(
            market: .withCondition,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: sells ? .sell(shares: Self.shares) : .buy(balance: .just(output: 200)),
            apiProvider: api,
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(state: .allowed),
            positionsService: positions,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: 200),
            addFundsReadinessStream: AsyncStream { $0.yield(.unavailable); $0.finish() },
            delayProvider: delayProvider,
            appStateObserver: appState
        )

        await Self.state(of: model) { $0.balance != nil }

        model.handleViewAction(.onAppear)

        if !sells {
            model.apply(enteredAmount: 100, debounced: false)
        }

        await Self.state(of: model) { $0.quote.quote != nil }

        return Context(model: model, api: api, positions: positions, appState: appState, delayProvider: delayProvider)
    }

    static func state(of model: PolymarketOrderModel, where isSatisfied: @escaping (PolymarketOrderModel.State) -> Bool) async {
        for await _ in model.$state.first(where: isSatisfied).values {
            return
        }
    }
}

private extension PolymarketMarket {
    static let withCondition = PolymarketMarket(
        id: "market",
        conditionId: "condition",
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

// MARK: - Doubles

private final class HeldPositionServiceStub: PolymarketPositionsService, Sendable {
    private struct State {
        var isOpen = false
        var waiting: [CheckedContinuation<Void, Never>] = []
    }

    struct StubError: Error {}

    private let size: Decimal
    private let state: OSAllocatedUnfairLock<State>

    init(size: Decimal, isOpen: Bool) {
        self.size = size
        state = OSAllocatedUnfairLock(initialState: State(isOpen: isOpen))
    }

    func open() {
        let waiting = state.withLock { state in
            state.isOpen = true
            defer { state.waiting = [] }
            return state.waiting
        }

        waiting.forEach { $0.resume() }
    }

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition? {
        await withCheckedContinuation { continuation in
            let resumesNow = state.withLock { state in
                guard !state.isOpen else { return true }

                state.waiting.append(continuation)
                return false
            }

            if resumesNow {
                continuation.resume()
            }
        }

        return PolymarketPosition(
            conditionId: conditionId,
            assetId: assetId,
            marketId: "market",
            version: .v1,
            eventId: nil,
            eventTitle: nil,
            title: "Question",
            iconURL: nil,
            endDate: nil,
            outcome: "Yes",
            outcomeIndex: 0,
            size: size,
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

    func activePositions(limit: Int) async throws -> PolymarketPositionsPage {
        throw StubError()
    }

    func openPositions(limit: Int, cursor: String?) async throws -> PolymarketPositionsPage {
        throw StubError()
    }

    func closedPositions(limit: Int, cursor: String?) async throws -> PolymarketClosedPositionsPage {
        throw StubError()
    }

    func awaitPosition(conditionId: String, assetId: String, changedFrom shares: Decimal?) async throws -> PolymarketPosition? {
        nil
    }
}
