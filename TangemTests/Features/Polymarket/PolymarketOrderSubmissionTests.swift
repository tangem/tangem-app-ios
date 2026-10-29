//
//  PolymarketOrderSubmissionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@MainActor
@Suite("Polymarket order submission", .timeLimit(.minutes(1)))
struct PolymarketOrderSubmissionTests {
    // MARK: - Readiness

    @Test("A quote received within the allowed age is ready to place")
    func freshQuoteIsReady() async throws {
        let model = try await makeQuotedModel()
        let sut = makeSUT(model: model, now: { Date() })

        guard case .ready(let quote) = sut.readiness() else {
            Issue.record("The fresh quote is not ready")
            return
        }

        #expect(quote == model.state.quote.quote)
    }

    @Test("A quote older than the allowed age is never placed")
    func oldQuoteIsStale() async throws {
        let model = try await makeQuotedModel()
        let sut = makeSUT(model: model, now: { Date().addingTimeInterval(PolymarketOrderModel.maxQuoteAge + 1) })

        guard case .staleQuote = sut.readiness() else {
            Issue.record("The old quote is still offered for placing")
            return
        }
    }

    @Test("Without a quote there is nothing to place")
    func missingQuoteIsUnavailable() async throws {
        let sut = makeSUT(model: await makeModel())

        guard case .unavailable = sut.readiness() else {
            Issue.record("An order without a quote is offered for placing")
            return
        }
    }

    // MARK: - Placement outcome

    @Test("A matched order that filled no shares is reported as a failure that leaves the order", arguments: [nil, Decimal(0)])
    func matchedWithoutFillFails(_ filledShares: Decimal?) async throws {
        let placement = PolymarketOrderPlacement(
            orderId: "order",
            status: .matched,
            makingAmount: 100,
            takingAmount: filledShares,
            transactionHashes: []
        )

        let outcome = await submit(placing: .success(placement))

        guard case .failed(let returningToMain) = outcome else {
            Issue.record("A matched order without shares is not reported as a failure")
            return
        }

        #expect(returningToMain)
    }

    @Test("A matched sale that sold no shares is reported as a failure that leaves the order")
    func matchedSaleWithoutSharesFails() async throws {
        let placement = PolymarketOrderPlacement(
            orderId: "order",
            status: .matched,
            makingAmount: 0,
            takingAmount: 5,
            transactionHashes: []
        )

        let outcome = await submit(placing: .success(placement), intent: .sell(shares: Self.heldShares))

        guard case .failed(let returningToMain) = outcome else {
            Issue.record("A sale that sold no shares is not reported as a failure")
            return
        }

        #expect(returningToMain)
    }

    @Test(
        "A signature the user cancelled is a quiet cancellation",
        arguments: PolymarketOrderSingleSheetTests.SigningCancellation.allCases
    )
    func cancelledSigningIsCancellation(_ cancellation: PolymarketOrderSingleSheetTests.SigningCancellation) async throws {
        let outcome = await submit(placing: .failure(cancellation.error))

        guard case .cancelled = outcome else {
            Issue.record("A cancelled signature is reported as \(outcome)")
            return
        }
    }

    @Test("An order that failed before it was sent stays on the sheet with an error")
    func unsentOrderFailsOnTheSheet() async throws {
        let outcome = await submit(placing: .failure(PolymarketOrderPlacementError.notSent(underlying: StubError())))

        guard case .failed(let returningToMain) = outcome else {
            Issue.record("An unsent order is reported as \(outcome)")
            return
        }

        #expect(!returningToMain)
    }

    // MARK: - Result content

    @Test("A sale reports the money the quote expected and the price it actually executed at")
    func sellResultShowsTheExecution() async throws {
        let quote = PolymarketOrderQuote.stub(status: .full, shares: Self.heldShares, expectedExecutionAmount: 7)
        let placement = PolymarketOrderPlacement(
            orderId: "order",
            status: .matched,
            makingAmount: Self.heldShares,
            takingAmount: Decimal(string: "6.5")!,
            transactionHashes: []
        )

        let outcome = await submit(placing: .success(placement), intent: .sell(shares: Self.heldShares), quote: quote)

        guard case .finished(let state, let content) = outcome else {
            Issue.record("A filled sale is reported as \(outcome)")
            return
        }

        #expect(state == .placed)
        #expect(content.side == .sell)
        #expect(content.orderedAmount == 7)
        #expect(content.filledAmount == Decimal(string: "6.5")!)
        #expect(content.tokensBought == Self.heldShares)
        #expect(content.heldShares == Self.heldShares)
        #expect(content.market.outcomePriceText == PolymarketPriceFormatter.centsText(Decimal(string: "0.65")!))
    }

    @Test("A purchase reports the amount the user entered and keeps the market row it was placed from")
    func buyResultShowsTheEnteredAmount() async throws {
        let placement = PolymarketOrderPlacement(
            orderId: "order",
            status: .matched,
            makingAmount: 100,
            takingAmount: 138,
            transactionHashes: []
        )
        let model = await makeModel()
        model.apply(enteredAmount: 100, debounced: false)
        let marketRow = PolymarketOrderMarketRow.Model.make(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            averagePrice: Decimal(string: "0.33")!
        )

        let outcome = await makeSUT(model: model, placing: .success(placement))
            .submit(quote: .stub(status: .full)) { marketRow }

        guard case .finished(let state, let content) = outcome else {
            Issue.record("A filled purchase is reported as \(outcome)")
            return
        }

        #expect(state == .placed)
        #expect(content.side == .buy)
        #expect(content.orderedAmount == 100)
        #expect(content.filledAmount == 100)
        #expect(content.tokensBought == 138)
        #expect(content.heldShares == nil)
        #expect(content.market.outcomePriceText == marketRow.outcomePriceText)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderSubmissionTests {
    static let heldShares: Decimal = 10

    struct StubError: Error {}

    func makeModel(intent: PolymarketOrderIntent = .buy(balance: .just(output: 200))) async -> PolymarketOrderModel {
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: intent,
            apiProvider: PolymarketAPIProviderStub(quoteResult: .stub(status: .full)),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(state: .allowed),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: 200),
            addFundsReadinessStream: AsyncStream { $0.yield(.unavailable); $0.finish() },
            delayProvider: PolymarketSteppedDelayProvider()
        )

        _ = await model.$state.firstValue { $0.balance != nil }

        return model
    }

    func makeQuotedModel() async throws -> PolymarketOrderModel {
        let model = await makeModel()

        model.apply(enteredAmount: 100, debounced: false)
        model.handleViewAction(.onAppear)

        _ = await model.$state.firstValue { $0.quote.quote != nil && $0.quoteReceivedAt != nil }

        return model
    }

    func makeSUT(
        model: PolymarketOrderModel,
        placing result: Result<PolymarketOrderPlacement, Error> = .failure(StubError()),
        now: @escaping () -> Date = Date.init
    ) -> PolymarketOrderSubmission {
        PolymarketOrderSubmission(model: model, placementService: PlacementServiceStub(result: result), now: now)
    }

    func submit(
        placing result: Result<PolymarketOrderPlacement, Error>,
        intent: PolymarketOrderIntent = .buy(balance: .just(output: 200)),
        quote: PolymarketOrderQuote = .stub(status: .full)
    ) async -> PolymarketOrderSubmission.Outcome {
        let model = await makeModel(intent: intent)
        let marketRow = PolymarketOrderMarketRow.Model.make(market: .fixture, outcome: .fixture, eventTitle: "Fixture event")

        return await makeSUT(model: model, placing: result).submit(quote: quote) { marketRow }
    }
}

// MARK: - Doubles

private struct PlacementServiceStub: PolymarketOrderPlacementService {
    let result: Result<PolymarketOrderPlacement, Error>

    func place(
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome
    ) async throws -> PolymarketOrderPlacement {
        try result.get()
    }
}
