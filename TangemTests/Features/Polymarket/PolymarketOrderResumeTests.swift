//
//  PolymarketOrderResumeTests.swift
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
@Suite("Polymarket quote after returning from background", .timeLimit(.minutes(1)))
struct PolymarketOrderResumeTests {
    // MARK: - Quote

    @Test("Coming back from background shows the quote as loading anew instead of the answer it had")
    func resumeShowsLoading() async throws {
        let resumed = try await resume(enteredAmount: 100)

        #expect(resumed.log.quotes.first?.isResuming == true)
    }

    @Test("One network failure of the quote after coming back is kept off the screen")
    func firstTransientQuoteFailureIsHidden() async throws {
        let resumed = try await resume(enteredAmount: 100, queuedQuotes: [.failure(Self.unavailable)])

        try await resumed.nextPoll()

        _ = await resumed.model.$state.firstValue { $0.quote.quote != nil }

        #expect(resumed.api.queuedQuoteResults.isEmpty)
        #expect(!resumed.log.quotes.contains { $0.isFailed })
    }

    @Test("A second network failure of the quote in a row after coming back is reported")
    func secondTransientQuoteFailureIsReported() async throws {
        let resumed = try await resume(enteredAmount: 100, queuedQuotes: [.failure(Self.unavailable), .failure(Self.unavailable)])

        try await resumed.nextPoll()

        _ = await resumed.model.$state.firstValue { $0.quote.isFailed }

        let firstFailure = try #require(resumed.log.quotes.firstIndex { $0.isFailed })

        #expect(firstFailure > 0)
        #expect(resumed.log.quotes[..<firstFailure].allSatisfy { $0.isResuming })
    }

    @Test("A refused quote after coming back is reported at once")
    func refusedQuoteIsReportedAtOnce() async throws {
        let resumed = try await resume(enteredAmount: 100, queuedQuotes: [.failure(Self.badRequest)])

        _ = await resumed.model.$state.firstValue { $0.quote.isFailed }

        let firstFailure = try #require(resumed.log.quotes.firstIndex { $0.isFailed })

        #expect(firstFailure == 1)
        #expect(resumed.log.quotes.first?.isResuming == true)
        #expect(resumed.api.quoteRequests.count == 2)
    }

    // MARK: - Book price

    @Test("Without an amount, coming back from background shows the book price as loading")
    func resumeShowsBookPriceLoading() async throws {
        let resumed = try await resume(enteredAmount: nil)

        #expect(resumed.log.states.first?.isBookPriceResuming == true)
    }

    @Test("A refused book price after coming back opens the error sheet at once")
    func refusedBookPriceIsReportedAtOnce() async throws {
        let resumed = try await resume(enteredAmount: nil, queuedPrices: [.failure(Self.noOrderBook)])

        _ = await resumed.model.$state.firstValue { $0.bookPriceFailure != nil }

        #expect(resumed.model.state.bookPriceFailure == .marketClosed)
        #expect(!resumed.model.state.isBookPriceResuming)
    }

    @Test("Network failures after coming back keep the book price loading instead of showing the old one")
    func networkFailuresKeepTheBookPriceLoading() async throws {
        let resumed = try await resume(
            enteredAmount: nil,
            queuedPrices: [.failure(Self.unavailable), .failure(Self.unavailable), .success(Self.freshPrice)]
        )

        try await resumed.nextPoll()
        try await resumed.nextPoll()

        _ = await resumed.model.$state.firstValue { $0.bookPrice == Self.freshPrice && !$0.isBookPriceResuming }

        let settled = resumed.log.states.filter { !$0.isBookPriceResuming }

        #expect(settled.allSatisfy { $0.bookPrice == Self.freshPrice })
        #expect(!resumed.log.states.contains { $0.bookPriceFailure != nil })
    }
}

// MARK: - Fixtures

private extension PolymarketOrderResumeTests {
    static let noOrderBook = PolymarketAPIError.http(statusCode: 404, problemDetail: nil)
    static let badRequest = PolymarketAPIError.http(statusCode: 400, problemDetail: nil)
    static let unavailable = PolymarketAPIError.http(statusCode: 503, problemDetail: nil)
    static let freshPrice: Decimal = 0.42
    static let pollInterval: TimeInterval = 3

    struct Resumed {
        let model: PolymarketOrderModel
        let api: PolymarketAPIProviderStub
        let delays: PolymarketSteppedDelayProvider
        let log: StateLog

        @MainActor
        func nextPoll() async throws {
            try await delays.waitUntilParked(PolymarketOrderResumeTests.pollInterval)
            delays.resume(PolymarketOrderResumeTests.pollInterval)
        }
    }

    func resume(
        enteredAmount: Decimal?,
        queuedQuotes: [Result<PolymarketOrderQuote, Error>] = [],
        queuedPrices: [Result<Decimal, Error>] = []
    ) async throws -> Resumed {
        let api = PolymarketAPIProviderStub(quoteResult: .stub(status: .full))
        let clob = PolymarketCLOBServiceStub()
        let delays = PolymarketSteppedDelayProvider()
        let appState = AppStateObserverStub()
        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: .buy(balance: .just(output: 200)),
            apiProvider: api,
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            positionsService: nil,
            clobService: clob,
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: 200),
            addFundsReadinessStream: AsyncStream { $0.yield(.unavailable); $0.finish() },
            delayProvider: delays,
            appStateObserver: appState
        )

        _ = await model.$state.firstValue { $0.balance != nil }

        if let enteredAmount {
            model.apply(enteredAmount: enteredAmount, debounced: false)
        }

        model.handleViewAction(.onAppear)
        try await delays.waitUntilParked(Self.pollInterval)

        appState.enterBackground()
        try await delays.cancellations.next()

        api.queuedQuoteResults = queuedQuotes
        clob.queuedPriceResults = queuedPrices

        let log = StateLog()
        log.observe(model)

        appState.enterForeground()
        _ = await model.$state.firstValue { $0.quote.isResuming || $0.isBookPriceResuming }

        return Resumed(model: model, api: api, delays: delays, log: log)
    }
}

// MARK: - Doubles

private final class StateLog {
    private(set) var states: [PolymarketOrderModel.State] = []
    private var bag: Set<AnyCancellable> = []

    var quotes: [PolymarketOrderQuoteState] {
        states.map(\.quote).reduce(into: []) { quotes, quote in
            if quotes.last != quote {
                quotes.append(quote)
            }
        }
    }

    @MainActor
    func observe(_ model: PolymarketOrderModel) {
        model.$state
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] in self?.states.append($0) }
            .store(in: &bag)
    }
}
