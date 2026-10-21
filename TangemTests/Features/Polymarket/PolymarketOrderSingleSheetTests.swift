//
//  PolymarketOrderSingleSheetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemUI
@testable import Tangem

@MainActor
@Suite("Polymarket order on a single sheet")
struct PolymarketOrderSingleSheetTests {
    // MARK: - Routing

    @Test("With phase two off a buy keeps the separate fee step")
    func toggleOffKeepsSummaryStepForBuy() {
        #expect(!PolymarketOrderFlowStyle(isSingleSheetEnabled: false, side: .buy, singleSheet: Self.singleSheet).isSingleSheet)
    }

    @Test("With phase two on a buy is placed from the single sheet")
    func toggleOnUsesSingleSheetForBuy() {
        #expect(PolymarketOrderFlowStyle(isSingleSheetEnabled: true, side: .buy, singleSheet: Self.singleSheet).isSingleSheet)
    }

    @Test("Closing a position keeps the fee step whatever the toggle says", arguments: [false, true])
    func sellAlwaysKeepsSummaryStep(isSingleSheetEnabled: Bool) {
        #expect(!PolymarketOrderFlowStyle(isSingleSheetEnabled: isSingleSheetEnabled, side: .sell, singleSheet: Self.singleSheet).isSingleSheet)
    }

    @Test("Without a placement the primary action opens the fee step and never places")
    func summaryStepOpensSummary() async throws {
        let context = try await makeContext(isSingleSheet: false)

        context.sut.handleViewAction(.placeOrder)
        context.sut.handleViewAction(.openSummary)

        #expect(!context.sut.isSingleSheet)
        #expect(!context.sut.showsTotal)
        #expect(context.sut.nextButtonTitle == Localization.commonNext)
        #expect(context.routable.summaryOpenings == 1)
        #expect(context.placementService.placements == 0)
    }

    @Test("With a placement the primary action places the order without the fee step")
    func singleSheetPlacesDirectly() async throws {
        let context = try await makeContext(isSingleSheet: true, placement: .success(.stub(makingAmount: 100, takingAmount: 138)))

        context.sut.handleViewAction(.placeOrder)

        try await settle { context.routable.results.count == 1 }

        #expect(context.sut.nextButtonTitle == Localization.predictionPlaceButton)
        #expect(context.routable.summaryOpenings == 0)
        #expect(context.placementService.placements == 1)
    }

    // MARK: - Total row

    @Test("The single sheet offers the dollar presets and Max, the fee step offers none")
    func amountPresetsFollowTheFlow() async throws {
        let single = try await makeContext(isSingleSheet: true, enteredAmount: nil)
        let summary = try await makeContext(isSingleSheet: false, enteredAmount: nil)

        #expect(single.sut.amountPresets.map(\.kind) == [.amount(100), .amount(500), .amount(1000), .amount(5000), .max])
        #expect(summary.sut.amountPresets.isEmpty)
    }

    @Test("Tapping a dollar preset enters that amount")
    func amountPresetEntersItsAmount() async throws {
        let context = try await makeContext(isSingleSheet: true, enteredAmount: nil)

        context.sut.handleViewAction(.selectPreset(.amount(500)))

        try await settle { context.model.state.enteredAmount == 500 }
    }

    @Test("A book too thin for the whole amount still shows its quoted total")
    func partialLiquidityShowsTheTotal() async throws {
        let quote = PolymarketOrderQuote.stub(status: .insufficientLiquidity)
        let context = try await makeContext(isSingleSheet: true, enteredAmount: nil, quote: quote)

        context.model.apply(enteredAmount: 100, debounced: false)

        try await settle { context.model.state.quote.partialQuote != nil }

        #expect(context.sut.totalText == PolymarketOrderFormatter.money(quote.total))
        #expect(context.sut.isFeeBreakdownAvailable)
    }

    @Test("The fee breakdown of a partially fillable quote shows its fees on the single sheet only")
    func partialLiquidityFeeBreakdown() async throws {
        let quote = PolymarketOrderQuote.stub(status: .insufficientLiquidity)
        let context = try await makeContext(isSingleSheet: true, enteredAmount: nil, quote: quote)

        context.model.apply(enteredAmount: 100, debounced: false)

        try await settle { context.model.state.quote.partialQuote != nil }

        let singleSheet = PolymarketFeeBreakdownSheetViewModel(model: context.model, includesPartialQuote: true)
        let summaryStep = PolymarketFeeBreakdownSheetViewModel(model: context.model)

        #expect(singleSheet.total == PolymarketOrderFormatter.money(quote.total))
        #expect(singleSheet.polymarketFee == PolymarketOrderFormatter.money(quote.fees.market))
        #expect(summaryStep.total != PolymarketOrderFormatter.money(quote.total))
    }

    @Test("The total row waits for an amount")
    func totalHiddenWithoutAmount() async throws {
        let context = try await makeContext(isSingleSheet: true, enteredAmount: nil)

        #expect(!context.sut.showsTotal)
        #expect(!context.sut.isFeeBreakdownAvailable)
        #expect(!context.sut.isNextEnabled)
    }

    @Test("An amount with a quote shows the quoted total and opens the fee breakdown")
    func totalShowsQuotedTotal() async throws {
        let context = try await makeContext(isSingleSheet: true)

        context.sut.handleViewAction(.openFeeBreakdown)

        #expect(context.sut.showsTotal)
        #expect(!context.sut.isTotalLoading)
        #expect(context.sut.totalText == PolymarketOrderFormatter.money(Self.quote.total))
        #expect(context.routable.feeBreakdownOpenings == 1)
    }

    @Test("The fee breakdown stays shut while the quote is missing")
    func feeBreakdownNeedsQuote() async throws {
        let context = try await makeContext(isSingleSheet: true, quote: nil)

        context.sut.handleViewAction(.openFeeBreakdown)

        #expect(context.sut.showsTotal)
        #expect(!context.sut.isFeeBreakdownAvailable)
        #expect(context.routable.feeBreakdownOpenings == 0)
    }

    // MARK: - Place button

    @Test("A covered amount with a placeable quote enables Place predict")
    func coveredAmountEnablesPlacing() async throws {
        let context = try await makeContext(isSingleSheet: true, enteredAmount: 100, balance: 200)

        #expect(context.sut.isNextEnabled)
    }

    @Test("A total above the balance keeps Place predict disabled and places nothing")
    func uncoveredAmountDisablesPlacing() async throws {
        let context = try await makeContext(isSingleSheet: true, enteredAmount: 100, balance: 50)

        context.sut.handleViewAction(.placeOrder)

        #expect(!context.sut.isNextEnabled)
        #expect(context.placementService.placements == 0)
    }

    // MARK: - Result mapping

    @Test("A fill of the quoted size opens the placed result")
    func fullFillOpensPlaced() async throws {
        let state = try await place(.success(.stub(makingAmount: 100, takingAmount: 138)))

        #expect(state == .placed)
    }

    @Test("A fill under the quoted size opens the partially placed result")
    func partialFillOpensPartiallyPlaced() async throws {
        let state = try await place(.success(.stub(makingAmount: 50, takingAmount: 69)))

        #expect(state == .partiallyPlaced)
    }

    @Test("An empty book opens the no liquidity result")
    func noLiquidityOpensNoFill() async throws {
        let state = try await place(.failure(PolymarketOrderPlacementError.noLiquidity(message: nil)))

        #expect(state == .noFill)
    }

    @Test("A sent order with an unknown outcome opens the still processing result")
    func ambiguousOpensStillProcessing() async throws {
        let state = try await place(.failure(PolymarketOrderPlacementError.ambiguous(underlying: StubError())))

        #expect(state == .stillProcessing)
    }

    @Test("A rejected order stays on the sheet with the error alert and can be placed again")
    func rejectionShowsAlert() async throws {
        let context = try await makeContext(isSingleSheet: true, placement: .failure(PolymarketOrderPlacementError.rejected(message: nil)))

        context.sut.handleViewAction(.placeOrder)

        try await settle { context.sut.alert != nil }

        #expect(!context.sut.isPlacing)
        #expect(context.routable.results.isEmpty)
    }

    @Test("A cancelled signature returns to the sheet silently")
    func cancelledSigningResumes() async throws {
        let context = try await makeContext(isSingleSheet: true, placement: .failure(CancellationError()))

        context.sut.handleViewAction(.placeOrder)

        try await settle { context.placementService.placements == 1 && !context.sut.isPlacing }

        #expect(context.sut.alert == nil)
        #expect(context.routable.results.isEmpty)
    }

    // MARK: - Tap before the quote

    @Test("A tap while the quote loads places the order once the quote arrives")
    func tapWhileQuotingPlacesOnceQuoted() async throws {
        let context = try await makeQuotingContext(placement: .success(.stub(makingAmount: 100, takingAmount: 138)))

        context.sut.handleViewAction(.placeOrder)

        #expect(context.sut.isPlacing)
        #expect(context.placementService.placements == 0)

        context.api.holdsQuotes = false
        context.api.releaseQuotes()

        try await settle { context.routable.results.count == 1 }

        context.model.handleViewAction(.retryQuote)
        try await settle { context.model.state.quote.quote != nil }

        #expect(context.placementService.placements == 1)
    }

    @Test("A tap while the quote loads is released when the quote fails")
    func tapWhileQuotingReleasedOnFailure() async throws {
        let context = try await makeQuotingContext()
        context.api.queuedQuoteResults = [.failure(StubError())]

        context.sut.handleViewAction(.placeOrder)
        context.api.holdsQuotes = false
        context.api.releaseQuotes()

        try await settle { !context.sut.isPlacing }

        #expect(context.placementService.placements == 0)
    }

    @Test("A tap while the quote loads is released when the arrived quote can't be placed")
    func tapWhileQuotingReleasedWhenGateCloses() async throws {
        let context = try await makeQuotingContext()
        context.api.queuedQuoteResults = [.success(.stub(status: .insufficientLiquidity))]

        context.sut.handleViewAction(.placeOrder)
        context.api.holdsQuotes = false
        context.api.releaseQuotes()

        try await settle { !context.sut.isPlacing }

        #expect(context.placementService.placements == 0)
        #expect(context.routable.closings == 0)
    }

    @Test("A tap is not placed when its quote arrives too late")
    func lateQuoteDoesNotPlace() async throws {
        let context = try await makeQuotingContext(placement: .success(.stub(makingAmount: 100, takingAmount: 138)))

        context.sut.handleViewAction(.placeOrder)
        context.clock.now += 60
        context.api.holdsQuotes = false
        context.api.releaseQuotes()

        try await settle { !context.sut.isPlacing }

        #expect(context.placementService.placements == 0)
    }

    @Test("Leaving the sheet drops a tap waiting for its quote")
    func leavingDropsPendingTap() async throws {
        let context = try await makeQuotingContext(placement: .success(.stub(makingAmount: 100, takingAmount: 138)))

        context.sut.handleViewAction(.placeOrder)
        context.sut.handleViewAction(.onDisappear)

        #expect(!context.sut.isPlacing)

        context.api.holdsQuotes = false
        context.api.releaseQuotes()
        try await drain()

        #expect(context.placementService.placements == 0)
    }

    @Test("Closing is ignored while the order is being placed")
    func closeIgnoredWhilePlacing() async throws {
        let context = try await makeContext(isSingleSheet: true, placement: nil)

        context.sut.handleViewAction(.placeOrder)

        try await settle { context.placementService.isPending }

        context.sut.handleViewAction(.close)

        #expect(context.sut.isPlacing)
        #expect(context.routable.closings == 0)

        context.placementService.resume(with: .failure(CancellationError()))

        try await settle { !context.sut.isPlacing }
    }
}

// MARK: - Fixtures

private extension PolymarketOrderSingleSheetTests {
    static let quote = PolymarketOrderQuote.stub(status: .full)
    static let singleSheet = PolymarketOrderFlowStyle.SingleSheet(placementService: PlacementServiceStub(result: nil), signingButtonType: .holdToConfirm)

    struct StubError: Error {}

    struct Context {
        let sut: PolymarketOrderViewModel
        let model: PolymarketOrderModel
        let routable: OrderRoutableSpy
        let placementService: PlacementServiceStub
        let api: PolymarketAPIProviderStub
        let clock: Clock
    }

    final class Clock {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
    }

    func makeQuotingContext(placement: Result<PolymarketOrderPlacement, Error>? = .failure(CancellationError())) async throws -> Context {
        let context = try await makeContext(isSingleSheet: true, enteredAmount: nil, placement: placement)

        context.api.holdsQuotes = true
        context.model.apply(enteredAmount: 100, debounced: false)

        try await settle { context.api.hasHeldQuotes && context.sut.isNextEnabled }

        return context
    }

    func place(_ result: Result<PolymarketOrderPlacement, Error>) async throws -> PolymarketOrderResultViewModel.State? {
        let context = try await makeContext(isSingleSheet: true, placement: result)

        context.sut.handleViewAction(.placeOrder)

        try await settle { !context.routable.results.isEmpty }

        return context.routable.results.first
    }

    func makeContext(
        isSingleSheet: Bool,
        enteredAmount: Decimal? = 100,
        balance: Decimal = 200,
        quote: PolymarketOrderQuote? = .stub(status: .full),
        placement: Result<PolymarketOrderPlacement, Error>? = .failure(CancellationError())
    ) async throws -> Context {
        let api = PolymarketAPIProviderStub(quoteResult: quote)
        let routable = OrderRoutableSpy()
        let placementService = PlacementServiceStub(result: placement)
        let clock = Clock()

        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: .buy(balance: .just(output: balance)),
            apiProvider: api,
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(state: .allowed),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: balance),
            addFundsReadinessStream: AsyncStream { $0.yield(.unavailable); $0.finish() }
        )

        let sut = PolymarketOrderViewModel(
            model: model,
            flowStyle: isSingleSheet
                ? .singleSheet(.init(placementService: placementService, signingButtonType: .holdToConfirm))
                : .summaryStep,
            coordinator: routable,
            now: { clock.now }
        )

        try await settle { model.state.balance != nil && model.state.geoblock == .allowed }

        model.handleViewAction(.onAppear)

        if let enteredAmount {
            model.apply(enteredAmount: enteredAmount, debounced: false)

            if quote != nil {
                try await settle { model.state.quote.quote != nil && (!isSingleSheet || sut.showsTotal && sut.isFeeBreakdownAvailable) }
            } else {
                try await settle { model.state.quote.isFailed && (!isSingleSheet || sut.showsTotal) }
            }
        }

        return Context(sut: sut, model: model, routable: routable, placementService: placementService, api: api, clock: clock)
    }
}

// MARK: - Doubles

private final class PlacementServiceStub: PolymarketOrderPlacementService {
    private struct State {
        var placements = 0
        var pending: CheckedContinuation<PolymarketOrderPlacement, Error>?
    }

    private let result: Result<PolymarketOrderPlacement, Error>?
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(result: Result<PolymarketOrderPlacement, Error>?) {
        self.result = result
    }

    var placements: Int {
        state.withLock { $0.placements }
    }

    var isPending: Bool {
        state.withLock { $0.pending != nil }
    }

    func resume(with result: Result<PolymarketOrderPlacement, Error>) {
        let pending = state.withLock { state in
            defer { state.pending = nil }
            return state.pending
        }

        pending?.resume(with: result)
    }

    func place(
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome
    ) async throws -> PolymarketOrderPlacement {
        state.withLock { $0.placements += 1 }

        if let result {
            return try result.get()
        }

        return try await withCheckedThrowingContinuation { continuation in
            state.withLock { $0.pending = continuation }
        }
    }
}

private final class OrderRoutableSpy: PolymarketOrderRoutable {
    private(set) var summaryOpenings = 0
    private(set) var feeBreakdownOpenings = 0
    private(set) var closings = 0
    private(set) var results: [PolymarketOrderResultViewModel.State] = []

    func closeOrder() {
        closings += 1
    }

    func openMarketClosed() {}

    func openQuoteUnavailable() {}

    func openAddFunds() {}

    func openRegionWarning() {}

    func openSlippageSelector(percent: Decimal, onConfirm: @escaping (Decimal) -> Void) {}

    func openSummary(model: PolymarketOrderModel) {
        summaryOpenings += 1
    }

    func openFeeBreakdown(model: PolymarketOrderModel) {
        feeBreakdownOpenings += 1
    }

    func openResult(state: PolymarketOrderResultViewModel.State, content: PolymarketOrderResultViewModel.Content) {
        results.append(state)
    }

    func openLegalTerms(url: URL) {}

    func openSupport() {}
}

private extension PolymarketOrderPlacement {
    static func stub(makingAmount: Decimal, takingAmount: Decimal) -> Self {
        Self(
            orderId: "order",
            status: .matched,
            makingAmount: makingAmount,
            takingAmount: takingAmount,
            transactionHashes: []
        )
    }
}
