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
import TangemPolymarket
import TangemUI
@testable import Tangem

@MainActor
@Suite("Polymarket order on a single sheet", .timeLimit(.minutes(1)))
struct PolymarketOrderSingleSheetTests {
    // MARK: - Routing

    @Test("The single sheet toggle alone decides between the single sheet and the separate fee step", arguments: [true, false])
    func toggleDecidesTheFlowStyle(isSingleSheetEnabled: Bool) {
        let style = PolymarketOrderFlowStyle(
            isSingleSheetEnabled: isSingleSheetEnabled,
            singleSheet: .init(placementService: PlacementServiceStub(result: nil), signingButtonType: .holdToConfirm)
        )

        #expect(style.isSingleSheet == isSingleSheetEnabled)
    }

    @Test("Without a placement the primary action opens the fee step and never places")
    func summaryStepOpensSummary() async throws {
        let context = try await makeContext(isSingleSheet: false)

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))
        context.sut.handleViewAction(.openSummary)

        #expect(!context.sut.isPlacing)
        #expect(!context.sut.showsTotal)
        #expect(context.routable.summaryOpenings == 1)
        #expect(context.placementService.placements == 0)
    }

    @Test("With a placement the primary action places the order without the fee step")
    func singleSheetPlacesDirectly() async throws {
        let context = try await makeContext(isSingleSheet: true, placement: .success(.stub(makingAmount: 100, takingAmount: 138)))

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        try await context.routable.resultOpened.next()

        #expect(context.routable.summaryOpenings == 0)
        #expect(context.placementService.placements == 1)
    }

    // MARK: - Fast trading

    @Test("An order on a device with a usable session key is signed by the session key")
    func usableSessionKeySignsTheOrder() async throws {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true)
        let choice = PolymarketOrderSigningChoice(availability: availability, showNotice: { _ in })
        let context = try await makeContext(isSingleSheet: true, placement: .success(.stub(makingAmount: 100, takingAmount: 138)), signingChoice: choice)

        try #require(choice.method == .sessionKey)

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        try await context.routable.resultOpened.next()

        #expect(context.placementService.signings == [.sessionKey(PolymarketSessionKeySigningAvailabilityStub.session)])
    }

    @Test("A session key lost between showing the button and the tap leaves the order for a card signature")
    func lostSessionKeyWaitsForTheCard() async throws {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true)
        let choice = PolymarketOrderSigningChoice(availability: availability, showNotice: { _ in })
        let context = try await makeContext(isSingleSheet: true, placement: .success(.stub(makingAmount: 100, takingAmount: 138)), signingChoice: choice)

        availability.publish(false)
        context.sut.handleViewAction(.placeOrder(signing: .sessionKey))

        await context.sut.$isPlacing.firstValue(where: { !$0 })

        #expect(context.placementService.placements == 0)
        #expect(choice.method == .ownerKey)

        _ = await context.model.$state.firstValue { $0.quote.quote != nil && !$0.quote.isAwaitingQuote }
        _ = await context.sut.$isNextEnabled.firstValue { $0 }
        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        try await context.routable.resultOpened.next()

        #expect(context.placementService.signings == [.ownerKey])
    }

    @Test("A session key the entry check could not confirm turns the tap to the card without placing the order or a support alert")
    func unconfirmedSessionKeyFallsBackToTheCard() async throws {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true, readiness: .ownerKey)
        let notices = TestSignal<String>()
        let choice = PolymarketOrderSigningChoice(availability: availability, showNotice: { notices.send($0) })
        let context = try await makeContext(
            isSingleSheet: true,
            placement: .success(.stub(makingAmount: 100, takingAmount: 138)),
            signingChoice: choice
        )
        _ = await context.sut.$isNextEnabled.firstValue { $0 }

        context.sut.handleViewAction(.placeOrder(signing: .sessionKey))

        await context.sut.$isPlacing.firstValue(where: { !$0 })

        #expect(context.placementService.placements == 0)
        #expect(context.sut.alert == nil)
        #expect(choice.method == .ownerKey)
        #expect(notices.recorded == [PolymarketFastTradingStrings.sessionKeyUnavailableNotice])
    }

    @Test("A session key the exchange turns down switches the order to a card signature without placing it")
    func refusedSessionKeyWaitsForTheCard() async throws {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true)
        let choice = PolymarketOrderSigningChoice(availability: availability, showNotice: { _ in })
        let context = try await makeContext(
            isSingleSheet: true,
            placement: .failure(PolymarketOrderPlacementSetupError.sessionKeyUnavailable),
            signingChoice: choice
        )

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        await context.sut.$isPlacing.firstValue(where: { !$0 })

        #expect(context.placementService.placements == 1)
        #expect(choice.method == .ownerKey)
        #expect(context.sut.alert == nil)
    }

    // MARK: - Closing a position

    @Test("Closing on the single sheet shows the proceeds and the total and offers no dollar presets")
    func singleSheetCloseShowsProceeds() async throws {
        let context = try await makeContext(isSingleSheet: true, sells: true, quote: Self.sellQuote)

        #expect(!context.sut.isAmountEditable)
        #expect(context.sut.amountPresets.isEmpty)
        #expect(context.sut.proceedsText == PolymarketOrderFormatter.money(Self.sellQuote.expectedExecutionAmount))
        #expect(context.sut.showsTotal)
        #expect(context.sut.totalText == PolymarketOrderFormatter.money(Self.sellQuote.total))
        #expect(context.sut.isFeeBreakdownAvailable)
    }

    @Test("Closing on the single sheet sells right away and hands over the whole held position")
    func singleSheetCloseSellsDirectly() async throws {
        let context = try await makeContext(
            isSingleSheet: true,
            sells: true,
            quote: Self.sellQuote,
            placement: .success(.stub(makingAmount: Self.heldShares, takingAmount: 7))
        )

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        try await context.routable.resultOpened.next()

        let content = try #require(context.routable.contents.first)

        #expect(context.routable.summaryOpenings == 0)
        #expect(context.placementService.placements == 1)
        #expect(content.side == .sell)
        #expect(content.heldShares == Self.heldShares)
        #expect(content.tokensBought == Self.heldShares)
    }

    // MARK: - Total row

    @Test("The single sheet offers dollar presets ending with Max, the fee step offers none")
    func amountPresetsFollowTheFlow() async throws {
        let single = try await makeContext(isSingleSheet: true, enteredAmount: nil)
        let summary = try await makeContext(isSingleSheet: false, enteredAmount: nil)

        #expect(single.sut.amountPresets.count > 1)
        #expect(single.sut.amountPresets.last?.kind == .max)
        #expect(single.sut.amountPresets.dropLast().allSatisfy { $0.kind != .max })
        #expect(summary.sut.amountPresets.isEmpty)
    }

    @Test("A book too thin for the whole amount shows no total and keeps the fee breakdown shut")
    func insufficientLiquidityHidesTheTotal() async throws {
        let quote = PolymarketOrderQuote.stub(status: .insufficientLiquidity)
        let context = try await makeContext(isSingleSheet: true, enteredAmount: nil, quote: quote)

        context.model.apply(enteredAmount: 100, debounced: false)

        _ = await context.sut.$isProceedsStale.firstValue { !$0 }

        context.sut.handleViewAction(.openFeeBreakdown)

        #expect(context.model.state.quote == .unavailable(.insufficientLiquidity, quote: quote))
        #expect(context.sut.totalText == BalanceFormatter.defaultEmptyBalanceString)
        #expect(!context.sut.isFeeBreakdownAvailable)
        #expect(context.routable.feeBreakdownOpenings == 0)
    }

    @Test("A fee breakdown left open shows no fees once the book can't fill the amount")
    func insufficientLiquidityFeeBreakdown() async throws {
        let quote = PolymarketOrderQuote.stub(status: .insufficientLiquidity)
        let context = try await makeContext(isSingleSheet: true, enteredAmount: nil, quote: quote)

        context.model.apply(enteredAmount: 100, debounced: false)

        _ = await context.model.$state.firstValue { $0.quote == .unavailable(.insufficientLiquidity, quote: quote) }

        let sheet = PolymarketFeeBreakdownSheetViewModel(model: context.model)

        #expect(sheet.total == BalanceFormatter.defaultEmptyBalanceString)
        #expect(sheet.polymarketFee == BalanceFormatter.defaultEmptyBalanceString)
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

    @Test("A total above the balance keeps Place predict disabled and places nothing")
    func uncoveredAmountDisablesPlacing() async throws {
        let context = try await makeContext(isSingleSheet: true, enteredAmount: 100, balance: 50)

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        #expect(!context.sut.isNextEnabled)
        #expect(!context.sut.isPlacing)
        #expect(context.placementService.placements == 0)
    }

    // MARK: - Result mapping

    @Test("A fill of the quoted size opens the placed result")
    func fullFillOpensPlaced() async throws {
        let state = try await place(.success(.stub(makingAmount: 100, takingAmount: 138)))

        #expect(state == .placed)
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

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        _ = await context.sut.$alert.firstValue { $0 != nil }

        #expect(!context.sut.isPlacing)
        #expect(context.routable.results.isEmpty)

        _ = await context.sut.$isNextEnabled.firstValue { $0 }
    }

    @Test("A cancelled signature returns to the sheet silently", arguments: SigningCancellation.allCases)
    func cancelledSigningResumes(_ cancellation: SigningCancellation) async throws {
        let context = try await makeContext(isSingleSheet: true, placement: .failure(cancellation.error))

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        _ = await context.sut.$isPlacing.firstValue { !$0 }

        #expect(context.placementService.placements == 1)
        #expect(context.sut.alert == nil)
        #expect(context.routable.results.isEmpty)
    }

    // MARK: - Tap before the quote

    @Test("Place predict stays off while the quote loads, and a tap then is not kept for the quote")
    func tapWhileQuotingPlacesNothing() async throws {
        let context = try await makeQuotingContext(placement: .success(.stub(makingAmount: 100, takingAmount: 138)))

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        #expect(!context.sut.isNextEnabled)
        #expect(!context.sut.isPlacing)

        context.api.holdsQuotes = false
        context.api.releaseQuotes()

        _ = await context.sut.$isNextEnabled.firstValue { $0 }

        #expect(!context.sut.isPlacing)
        #expect(context.placementService.placements == 0)
    }

    @Test("Closing is ignored while the order is being placed")
    func closeIgnoredWhilePlacing() async throws {
        let context = try await makeContext(isSingleSheet: true, placement: nil)

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        try await context.placementService.entered.next()

        context.sut.handleViewAction(.close)

        #expect(context.sut.isPlacing)
        #expect(context.routable.closings == 0)

        context.placementService.resume(with: .failure(CancellationError()))

        _ = await context.sut.$isPlacing.firstValue { !$0 }

        context.sut.handleViewAction(.close)

        #expect(context.routable.closings == 1)
    }
}

// MARK: - Fixtures

extension PolymarketOrderSingleSheetTests {
    enum SigningCancellation: CaseIterable, Sendable {
        case task
        case cardPrompt
        case taskBeforeSending

        var error: Error {
            switch self {
            case .task:
                return CancellationError()
            case .cardPrompt:
                return PolymarketOrderPlacementError.notSent(underlying: PolymarketSigningError.cancelled)
            case .taskBeforeSending:
                return PolymarketOrderPlacementError.notSent(underlying: CancellationError())
            }
        }
    }
}

private extension PolymarketOrderSingleSheetTests {
    static let quote = PolymarketOrderQuote.stub(status: .full)
    static let heldShares: Decimal = 10
    static let sellQuote = PolymarketOrderQuote.stub(status: .full, shares: heldShares, expectedExecutionAmount: 7, total: Decimal(string: "6.5")!)

    struct StubError: Error {}

    struct Context {
        let sut: PolymarketOrderViewModel
        let model: PolymarketOrderModel
        let routable: OrderRoutableSpy
        let placementService: PlacementServiceStub
        let api: PolymarketAPIProviderStub
    }

    func makeQuotingContext(placement: Result<PolymarketOrderPlacement, Error>? = .failure(CancellationError())) async throws -> Context {
        let context = try await makeContext(isSingleSheet: true, enteredAmount: nil, placement: placement)

        context.api.holdsQuotes = true
        context.model.apply(enteredAmount: 100, debounced: false)

        try await context.api.heldQuoteEntered.next()
        _ = await context.sut.$isTotalLoading.firstValue { $0 }

        return context
    }

    func place(_ result: Result<PolymarketOrderPlacement, Error>) async throws -> PolymarketOrderResultViewModel.State? {
        let context = try await makeContext(isSingleSheet: true, placement: result)

        context.sut.handleViewAction(.placeOrder(signing: context.sut.signingMethod))

        try await context.routable.resultOpened.next()

        return context.routable.results.first
    }

    func makeContext(
        isSingleSheet: Bool,
        sells: Bool = false,
        enteredAmount: Decimal? = 100,
        balance: Decimal = 200,
        quote: PolymarketOrderQuote? = .stub(status: .full),
        placement: Result<PolymarketOrderPlacement, Error>? = .failure(CancellationError()),
        signingChoice: PolymarketOrderSigningChoice? = nil
    ) async throws -> Context {
        let api = PolymarketAPIProviderStub(quoteResult: quote)
        let routable = OrderRoutableSpy()
        let placementService = PlacementServiceStub(result: placement)
        let delays = PolymarketSteppedDelayProvider()

        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: sells ? .sell(shares: Self.heldShares) : .buy(balance: .just(output: balance)),
            apiProvider: api,
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(state: .allowed),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: balance),
            addFundsReadinessStream: AsyncStream { $0.yield(.unavailable); $0.finish() },
            delayProvider: delays
        )

        let sut = PolymarketOrderViewModel(
            model: model,
            flowStyle: isSingleSheet
                ? .singleSheet(.init(placementService: placementService, signingButtonType: .holdToConfirm))
                : .summaryStep,
            signingChoice: signingChoice,
            coordinator: routable
        )

        _ = await model.$state.firstValue { $0.balance != nil && $0.geoblock == .allowed }
        _ = await sut.$amountFractions.firstValue { !$0.isEmpty }

        if !sells, let enteredAmount {
            model.apply(enteredAmount: enteredAmount, debounced: false)
        }

        model.handleViewAction(.onAppear)

        if sells || enteredAmount != nil {
            if quote != nil {
                _ = await sut.$isProceedsStale.firstValue { !$0 }
            } else {
                _ = await sut.$proceedsText.firstValue { $0 == .enDashSign }
            }
        }

        return Context(
            sut: sut,
            model: model,
            routable: routable,
            placementService: placementService,
            api: api
        )
    }
}

// MARK: - Doubles

private final class PlacementServiceStub: PolymarketOrderPlacementService {
    let entered = TestSignal<Void>()

    private struct State {
        var placements = 0
        var signings: [PolymarketOrderSigningRoute] = []
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

    var signings: [PolymarketOrderSigningRoute] {
        state.withLock { $0.signings }
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
        outcome: PolymarketOutcome,
        signing: PolymarketOrderSigningRoute
    ) async throws -> PolymarketOrderPlacement {
        state.withLock { state in
            state.placements += 1
            state.signings.append(signing)
        }

        if let result {
            return try result.get()
        }

        return try await withCheckedThrowingContinuation { continuation in
            state.withLock { $0.pending = continuation }
            entered.send()
        }
    }
}

@MainActor
private final class OrderRoutableSpy: PolymarketOrderRoutable {
    let resultOpened = TestSignal<Void>()

    private(set) var summaryOpenings = 0
    private(set) var feeBreakdownOpenings = 0
    private(set) var closings = 0
    private(set) var results: [PolymarketOrderResultViewModel.State] = []
    private(set) var contents: [PolymarketOrderResultViewModel.Content] = []

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
        contents.append(content)
        resultOpened.send()
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
