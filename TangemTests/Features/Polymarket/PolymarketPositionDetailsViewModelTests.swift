//
//  PolymarketPositionDetailsViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket position details refresh", .timeLimit(.minutes(1)))
struct PolymarketPositionDetailsViewModelTests {
    @Test("Opening the details asks for the position afresh and shows the answer")
    func refreshesOnOpen() async {
        let context = Self.makeSUT(answers: [.success(.stub(size: 25, cashPnl: 3))])

        let refreshed = await context.nextPosition()

        #expect(refreshed?.size == 25)
        #expect(refreshed?.cashPnl == 3)
    }

    @Test("A missing or failed answer keeps what is on screen", arguments: [LookupAnswer.missing, .failure])
    func keepsThePositionWithoutAnAnswer(answer: LookupAnswer) async {
        let context = Self.makeSUT(answers: [answer.result, .success(.stub(size: 11))])

        await context.nextRequest()
        await context.nextParkedWait()
        context.delayProvider.releaseParkedWaits()

        #expect(await context.nextPosition()?.size == 11)
        #expect(context.routable.closings == 0)
    }

    @Test("The position keeps refreshing while the screen is open")
    func keepsPolling() async {
        let context = Self.makeSUT(answers: [
            .success(.stub(size: 11)),
            .success(.stub(size: 12)),
            .success(.stub(size: 13)),
        ])

        #expect(await context.nextPosition()?.size == 11)

        await context.nextParkedWait()
        context.delayProvider.releaseParkedWaits()
        #expect(await context.nextPosition()?.size == 12)

        await context.nextParkedWait()
        context.delayProvider.releaseParkedWaits()
        #expect(await context.nextPosition()?.size == 13)
    }

    @Test("Going to the background drops the answer still in flight")
    func backgroundDropsTheAnswerInFlight() async {
        let context = Self.makeSUT(answers: [.success(.stub(size: 11)), .success(.stub(size: 12))], holdsAnswers: true)

        await context.nextRequest()
        context.appState.enterBackground()
        #expect(context.service.cancellationCount == 1)

        context.service.release()
        context.appState.enterForeground()

        #expect(await context.nextPosition()?.size == 12)
    }

    @Test("Coming back from the background asks for the position at once")
    func foregroundAsksAtOnce() async {
        let context = Self.makeSUT(answers: [.success(.stub(size: 11)), .success(.stub(size: 12))])

        #expect(await context.nextPosition()?.size == 11)

        context.appState.enterForeground()

        #expect(await context.nextPosition()?.size == 12)
    }

    @Test("Buy and Cash out on a settled market with no notice open the unavailable sheet")
    func unavailableMarketOpensTheSheet() throws {
        let context = Self.makeSUT(position: .stub(settlement: .won), answers: [.success(nil)])

        try #require(context.sut.model.primaryAction).perform()
        try #require(context.sut.model.secondaryAction).perform()

        #expect(context.routable.marketUnavailableCount == 2)
    }
}

extension PolymarketPositionDetailsViewModelTests {
    enum LookupAnswer: Sendable, CaseIterable {
        case missing
        case failure

        var result: Result<PolymarketPosition?, Error> {
            switch self {
            case .missing: .success(nil)
            case .failure: .failure(PositionLookupStub.StubError())
            }
        }
    }
}

// MARK: - Helpers

private extension PolymarketPositionDetailsViewModelTests {
    @MainActor
    final class Context {
        let sut: PolymarketPositionDetailsViewModel
        let service: PositionLookupStub
        let routable: DetailsRoutableStub
        let appState: AppStateObserverStub
        let delayProvider: ParkingDelayProvider

        private var positions: AsyncStream<PolymarketPosition>.Iterator
        private var parkedWaits: AsyncStream<ParkingDelayProvider.Event>.Iterator
        private var requests: AsyncStream<Void>.Iterator
        private var bag: Set<AnyCancellable> = []

        init(
            sut: PolymarketPositionDetailsViewModel,
            service: PositionLookupStub,
            routable: DetailsRoutableStub,
            appState: AppStateObserverStub,
            delayProvider: ParkingDelayProvider
        ) {
            self.sut = sut
            self.service = service
            self.routable = routable
            self.appState = appState
            self.delayProvider = delayProvider

            let (positions, continuation) = AsyncStream<PolymarketPosition>.makeStream()
            self.positions = positions.makeAsyncIterator()
            parkedWaits = delayProvider.events.makeAsyncIterator()
            requests = service.requests.makeAsyncIterator()

            sut.$position
                .dropFirst()
                .sink { continuation.yield($0) }
                .store(in: &bag)
        }

        func nextPosition() async -> PolymarketPosition? {
            var positions = positions
            let position = await positions.next()
            self.positions = positions
            return position
        }

        func nextRequest() async {
            var requests = requests
            _ = await requests.next()
            self.requests = requests
        }

        func nextParkedWait() async {
            var parkedWaits = parkedWaits

            while let event = await parkedWaits.next() {
                if case .parked = event { break }
            }

            self.parkedWaits = parkedWaits
        }
    }

    static func makeSUT(
        position: PolymarketPosition = .stub(size: 10),
        answers: [Result<PolymarketPosition?, Error>],
        holdsAnswers: Bool = false
    ) -> Context {
        let service = PositionLookupStub(answers: answers, holdsAnswers: holdsAnswers)
        let routable = DetailsRoutableStub()
        let appState = AppStateObserverStub()
        let delayProvider = ParkingDelayProvider()

        let sut = PolymarketPositionDetailsViewModel(
            position: position,
            apiProvider: PolymarketAPIProviderStub(),
            positionsService: service,
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(),
            usesPhaseTwoLayout: false,
            onOrderPlaced: { _ in },
            coordinator: routable,
            poller: PolymarketForegroundPoller(interval: 20, appStateObserver: appState, delayProvider: delayProvider)
        )

        return Context(sut: sut, service: service, routable: routable, appState: appState, delayProvider: delayProvider)
    }
}

// MARK: - Doubles

private final class PositionLookupStub: PolymarketPositionsService, Sendable {
    struct StubError: Error {}

    private struct State {
        var answers: [Result<PolymarketPosition?, Error>]
        var holdsAnswers: Bool
        var cancellationCount = 0
        var held: [CheckedContinuation<Void, Never>] = []
    }

    let requests: AsyncStream<Void>

    private let state: OSAllocatedUnfairLock<State>
    private let requestsContinuation: AsyncStream<Void>.Continuation

    init(answers: [Result<PolymarketPosition?, Error>], holdsAnswers: Bool = false) {
        (requests, requestsContinuation) = AsyncStream.makeStream()
        state = OSAllocatedUnfairLock(initialState: State(answers: answers, holdsAnswers: holdsAnswers))
    }

    var cancellationCount: Int {
        state.withLock { $0.cancellationCount }
    }

    func release() {
        let held = state.withLock { state in
            state.holdsAnswers = false
            defer { state.held = [] }
            return state.held
        }

        held.forEach { $0.resume() }
    }

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition? {
        let (answer, holds) = state.withLock { state in
            let answer = state.answers.count > 1 ? state.answers.removeFirst() : state.answers.first
            return (answer, state.holdsAnswers)
        }

        guard holds else {
            requestsContinuation.yield()
            return try answer?.get()
        }

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let resumesNow = state.withLock { state in
                    guard state.holdsAnswers else { return true }

                    state.held.append(continuation)
                    return false
                }

                requestsContinuation.yield()

                if resumesNow {
                    continuation.resume()
                }
            }
        } onCancel: {
            state.withLock { $0.cancellationCount += 1 }
        }

        return try answer?.get()
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

private final class DetailsRoutableStub: PolymarketPositionDetailsRoutable {
    private(set) var closings = 0
    private(set) var marketUnavailableCount = 0

    func closePositionDetails() {
        closings += 1
    }

    func openRegionWarning() {}

    func openMarketClosed() {}

    func openMarketUnavailable() {
        marketUnavailableCount += 1
    }

    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {}

    func openEventDetails(
        eventID: String,
        placeholder: PolymarketEventPlaceholder?,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {}
}
