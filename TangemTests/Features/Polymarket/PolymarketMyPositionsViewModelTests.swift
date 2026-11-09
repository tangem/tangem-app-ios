//
//  PolymarketMyPositionsViewModelTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket my positions", .timeLimit(.minutes(1)))
struct PolymarketMyPositionsViewModelTests {
    // MARK: - Where a tapped row leads

    @Test("A settled row opens the claim screen and a running one opens the details")
    func tappedRowLeadsWhereItShould() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.page([Self.position(0, settlement: .won), Self.position(1)], nextCursor: nil),
        ])
        let routable = MyPositionsRoutableSpy()
        let sut = Self.makeSUT(service: service, coordinator: routable)
        await Self.loadingState(of: sut, becomes: .allDataLoaded)

        sut.handleViewAction(.openPositionDetails(id: "0x0/1"))
        sut.handleViewAction(.openPositionDetails(id: "0x1/1"))

        #expect(routable.redeemed.map(\.id) == ["0x0/1"])
        #expect(routable.detailed.map(\.id) == ["0x1/1"])
    }

    @Test("A claimed position leaves the list even when the reload still hands it back")
    func claimedPositionLeaves() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.page([Self.position(0, settlement: .won), Self.position(1)], nextCursor: nil),
        ])
        let routable = MyPositionsRoutableSpy()
        let sut = Self.makeSUT(service: service, coordinator: routable)
        await Self.loadingState(of: sut, becomes: .allDataLoaded)

        sut.handleViewAction(.openPositionDetails(id: "0x0/1"))
        let onClaimed = try #require(routable.onClaimed)
        onClaimed(Self.position(0, settlement: .won))

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(service.openCursors == [nil, nil])
        #expect(sut.rows.map(\.id) == ["0x1/1"])
    }

    // MARK: - Paging

    @Test("The next page is asked for with the cursor the server handed back")
    func nextPageFollowsTheServerCursor() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 20, nextCursor: "c1"),
            Self.openPage(count: 5, nextCursor: nil, firstIndex: 20),
        ])
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(service.openCursors == [nil, "c1"])
        #expect(sut.rows.count == 25)
    }

    @Test("A list the backend has ended is not asked for again")
    func loadMoreStopsAtTheEnd() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 2, nextCursor: nil)])
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .allDataLoaded)

        sut.handleViewAction(.loadNextPage)

        #expect(sut.loadingState == .allDataLoaded)
    }

    @Test("A filter that swallows whole pages asks in bounded bursts and never claims the list is empty")
    func emptyPagesAreBounded() async throws {
        let pages = (0 ..< 10).map { _ in Self.openPage(count: 5, nextCursor: "more") }
        let service = PolymarketPositionsServiceStub(openPages: pages)
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .loaded)

        sut.handleViewAction(.selectFilter(.won))

        await Self.loadingState(of: sut, becomes: .loaded)
        #expect(sut.rows.isEmpty)
        #expect(service.openCursors.count == 5)
    }

    @Test("A filter that swallows what is loaded keeps walking rather than stranding the list")
    func filterResumesTheWalk() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 2, nextCursor: "c1"),
            Self.openPage(count: 2, nextCursor: nil, settlement: .won, firstIndex: 2),
        ])
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .loaded)

        sut.handleViewAction(.selectFilter(.won))

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(sut.rows.count == 2)
        #expect(service.openCursors == [nil, "c1"])
    }

    @Test("Switching the tab drops a filter that cannot match anything on the other list")
    func tabSwitchResetsTheFilter() async throws {
        let service = PolymarketPositionsServiceStub(
            openPages: [Self.openPage(count: 1, nextCursor: nil)],
            closedPages: [Self.closedPage(count: 1, nextCursor: nil)]
        )
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .allDataLoaded)

        sut.handleViewAction(.selectFilter(.active))
        sut.tab = .finished

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(sut.filter == .all)
        #expect(sut.rows.count == 1)
        #expect(service.closedCursors == [nil])
    }

    @Test("A row the server repeats between pages is kept once, and the walk still follows the server")
    func repeatedRowsAreKeptOnce() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 3, nextCursor: "c1", firstIndex: 0),
            Self.openPage(count: 3, nextCursor: nil, firstIndex: 2),
        ])
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(service.openCursors == [nil, "c1"])
        #expect(sut.rows.count == 5)
    }

    @Test("A cursor the backend refuses starts the list over from the first page")
    func rejectedCursorReloads() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 2, nextCursor: "c1"),
            .failure(PolymarketAPIError.http(statusCode: 400, problemDetail: nil)),
            Self.openPage(count: 2, nextCursor: nil),
        ])
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(service.openCursors == [nil, "c1", nil])
        #expect(sut.rows.count == 2)
    }

    @Test("A first page that fails offers a retry, and the retry brings the list back")
    func theFirstFailureIsRecoverable() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            .failure(TestError.refused),
            Self.openPage(count: 2, nextCursor: nil),
        ])
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .error)
        #expect(sut.rows.isEmpty)

        sut.handleViewAction(.retry)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(sut.rows.count == 2)
    }

    @Test("A failure deeper in the list keeps what is already on screen")
    func aLaterFailureKeepsTheRows() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 2, nextCursor: "c1"),
            .failure(TestError.refused),
        ])
        let sut = Self.makeSUT(service: service)
        await Self.loadingState(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)

        await Self.loadingState(of: sut, becomes: .paginationError)
        #expect(sut.rows.count == 2)
    }

    // MARK: - Polling

    @Test("Polling asks again only for the pages on screen, each with the cursor it was loaded with")
    func pollingRefreshesVisiblePagesWithTheirCursors() async throws {
        let context = Self.makePollingContext(openPagesByCursor: [
            nil: [Self.openPage(count: 2, nextCursor: "c1")],
            "c1": [
                Self.openPage(count: 2, nextCursor: "c2", firstIndex: 2),
                Self.openPage(count: 2, nextCursor: "c2", firstIndex: 2, emptiedIndex: 3),
            ],
            "c2": [Self.openPage(count: 2, nextCursor: nil, firstIndex: 4)],
        ])
        await Self.loadingState(of: context.sut, becomes: .loaded)
        context.sut.handleViewAction(.loadNextPage)
        await Self.loadingState(of: context.sut, becomes: .loaded)
        context.sut.handleViewAction(.loadNextPage)
        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onRowVisibilityChange(id: "0x3/1", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.service.openCursors == [nil, "c1", "c2", "c1"])
        #expect(context.sut.rows.count == 5)
        #expect(!context.sut.rows.map(\.id).contains("0x3/1"))
    }

    @Test("A page refreshed recently or kept off screen is not asked for")
    func freshOrHiddenPagesAreNotRefreshed() async throws {
        let context = Self.makePollingContext(openPagesByCursor: [nil: [Self.openPage(count: 2, nextCursor: nil)]])
        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)

        context.sut.handleViewAction(.onRowVisibilityChange(id: "0x0/1", isVisible: true))
        try await context.runVisibilityTick()

        context.sut.handleViewAction(.onRowVisibilityChange(id: "0x0/1", isVisible: false))
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onRowVisibilityChange(id: "elsewhere", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.service.openCursors == [nil])

        context.sut.handleViewAction(.onRowVisibilityChange(id: "0x0/1", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.service.openCursors == [nil, nil])
    }

    @Test("A reload while a page is being refreshed drops the late answer")
    func reloadDropsTheStalePage() async throws {
        let context = Self.makePollingContext(openPagesByCursor: [
            nil: [
                Self.openPage(count: 2, nextCursor: nil),
                Self.openPage(count: 2, nextCursor: nil, emptiedIndex: 0),
                Self.openPage(count: 2, nextCursor: nil),
            ],
        ])
        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)
        let lateRefresh = context.service.holdOpenRequest(2)

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onRowVisibilityChange(id: "0x0/1", isVisible: true))
        try await context.delays.waitUntilParked(Delays.visibilitySettleDelay)
        context.delays.resume(Delays.visibilitySettleDelay)
        try await lateRefresh.entered.next()

        context.sut.reload()
        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)

        lateRefresh.open()
        context.sut.handleViewAction(.onRowVisibilityChange(id: "after-the-late-answer", isVisible: true))
        try await context.delays.waitUntilParked(Delays.visibilitySettleDelay)

        #expect(context.service.openCursors == [nil, nil, nil])
        #expect(context.sut.rows.map(\.id) == ["0x0/1", "0x1/1"])
    }

    @Test("A refreshed page whose cursor the backend refuses keeps the rows and is not asked for again")
    func refreshWithRejectedCursorKeepsTheRows() async throws {
        let context = Self.makePollingContext(openPagesByCursor: [
            nil: [Self.openPage(count: 2, nextCursor: "c1")],
            "c1": [
                Self.openPage(count: 2, nextCursor: nil, firstIndex: 2),
                .failure(PolymarketAPIError.http(statusCode: 400, problemDetail: nil)),
            ],
        ])
        await Self.loadingState(of: context.sut, becomes: .loaded)
        context.sut.handleViewAction(.loadNextPage)
        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onRowVisibilityChange(id: "0x2/1", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.service.openCursors == [nil, "c1", "c1"])
        #expect(context.sut.rows.count == 4)
        #expect(context.sut.loadingState == .allDataLoaded)

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onRowVisibilityChange(id: "0x3/1", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.service.openCursors == [nil, "c1", "c1"])
    }
}

// MARK: - Helpers

private extension PolymarketMyPositionsViewModelTests {
    @MainActor
    struct PollingContext {
        let sut: PolymarketMyPositionsViewModel
        let service: PolymarketPositionsServiceStub
        let clock: PositionsClock
        let delays: PolymarketSteppedDelayProvider

        func runVisibilityTick() async throws {
            try await delays.waitUntilParked(Delays.visibilitySettleDelay)
            delays.resume(Delays.visibilitySettleDelay)

            sut.handleViewAction(.onRowVisibilityChange(id: UUID().uuidString, isVisible: true))
            try await delays.waitUntilParked(Delays.visibilitySettleDelay)
        }
    }

    static func makeSUT(
        service: PolymarketPositionsServiceStub,
        coordinator: PolymarketMyPositionsRoutable? = nil,
        clock: PositionsClock = PositionsClock(),
        delays: PolymarketSteppedDelayProvider = PolymarketSteppedDelayProvider()
    ) -> PolymarketMyPositionsViewModel {
        PolymarketMyPositionsViewModel(
            tab: .active,
            positionsService: service,
            coordinator: coordinator,
            appStateObserver: AppStateObserverStub(),
            now: { clock.now },
            delayProvider: delays
        )
    }

    static func makePollingContext(
        openPagesByCursor: [String?: [Result<PolymarketPositionsPage, Error>]]
    ) -> PollingContext {
        let service = PolymarketPositionsServiceStub(openPagesByCursor: openPagesByCursor)
        let clock = PositionsClock()
        let delays = PolymarketSteppedDelayProvider()
        let sut = makeSUT(service: service, clock: clock, delays: delays)

        return PollingContext(sut: sut, service: service, clock: clock, delays: delays)
    }

    static func loadingState(of sut: PolymarketMyPositionsViewModel, becomes state: PolymarketMyPositionsViewModel.LoadingState) async {
        _ = await sut.$loadingState.firstValue { $0 == state }
    }

    static func page(_ positions: [PolymarketPosition], nextCursor: String?) -> Result<PolymarketPositionsPage, Error> {
        .success(PolymarketPositionsPage(positions: positions, receivedCount: positions.count, nextCursor: nextCursor))
    }

    static func openPage(
        count: Int,
        nextCursor: String?,
        settlement: PolymarketPositionSettlement? = nil,
        firstIndex: Int = 0,
        emptiedIndex: Int? = nil
    ) -> Result<PolymarketPositionsPage, Error> {
        page(
            (0 ..< count).map { offset in
                let index = firstIndex + offset
                return position(index, settlement: settlement, size: index == emptiedIndex ? 0 : 1)
            },
            nextCursor: nextCursor
        )
    }

    static func position(
        _ index: Int,
        settlement: PolymarketPositionSettlement? = nil,
        size: Decimal = 1
    ) -> PolymarketPosition {
        PolymarketPosition(
            conditionId: "0x\(index)",
            assetId: "1",
            marketId: "3",
            version: .v1,
            eventId: "4",
            eventTitle: "Event",
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
            resolutionStatus: settlement == nil ? .open : .resolved,
            settlement: settlement
        )
    }

    static func closedPage(count: Int, nextCursor: String?) -> Result<PolymarketClosedPositionsPage, Error> {
        .success(PolymarketClosedPositionsPage(
            positions: (0 ..< count).map { index in
                PolymarketClosedPosition(
                    conditionId: "0x\(index)",
                    assetId: "1",
                    title: "Question",
                    slug: nil,
                    iconURL: nil,
                    closedAt: nil,
                    outcome: "Yes",
                    outcomeIndex: 0,
                    avgPrice: 1,
                    curPrice: 1,
                    totalBought: 1,
                    realizedPnl: 0,
                    status: .closed
                )
            },
            receivedCount: count,
            nextCursor: nextCursor
        ))
    }
}

private enum Delays {
    static let visibilitySettleDelay: TimeInterval = 0.5
}

// MARK: - Doubles

private enum TestError: Error {
    case refused
}

private final class PositionsClock: Sendable {
    private let current = OSAllocatedUnfairLock(initialState: Date(timeIntervalSince1970: 1_800_000_000))

    var now: Date {
        current.withLock { $0 }
    }

    func advance(by interval: TimeInterval) {
        current.withLock { $0 = $0.addingTimeInterval(interval) }
    }
}

@MainActor
private final class PolymarketPositionsServiceStub: PolymarketPositionsService {
    private(set) var openCursors: [String?] = []
    private(set) var closedCursors: [String?] = []

    private let openPages: [Result<PolymarketPositionsPage, Error>]
    private let closedPages: [Result<PolymarketClosedPositionsPage, Error>]
    private var openPagesByCursor: [String?: [Result<PolymarketPositionsPage, Error>]]
    private var heldOpenRequests: [Int: PolymarketTestGate] = [:]

    init(
        openPages: [Result<PolymarketPositionsPage, Error>] = [],
        closedPages: [Result<PolymarketClosedPositionsPage, Error>] = [],
        openPagesByCursor: [String?: [Result<PolymarketPositionsPage, Error>]] = [:]
    ) {
        self.openPages = openPages
        self.closedPages = closedPages
        self.openPagesByCursor = openPagesByCursor
    }

    func holdOpenRequest(_ number: Int) -> PolymarketTestGate {
        let gate = PolymarketTestGate()
        heldOpenRequests[number] = gate
        return gate
    }

    func activePositions(limit: Int) async throws -> PolymarketPositionsPage {
        Issue.record("The positions list never asks for the active positions")
        return PolymarketPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
    }

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition? {
        nil
    }

    func awaitPosition(conditionId: String, assetId: String, changedFrom shares: Decimal?) async throws -> PolymarketPosition? {
        nil
    }

    func openPositions(limit: Int, cursor: String?) async throws -> PolymarketPositionsPage {
        openCursors.append(cursor)
        let page = nextOpenPage(cursor: cursor)

        if let gate = heldOpenRequests[openCursors.count] {
            await gate.pass()
        }

        guard let page else {
            Issue.record("The open list was asked for a page the stub does not have")
            return PolymarketPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
        }

        return try page.get()
    }

    func closedPositions(limit: Int, cursor: String?) async throws -> PolymarketClosedPositionsPage {
        closedCursors.append(cursor)

        guard let page = closedPages[safe: closedCursors.count - 1] ?? closedPages.last else {
            Issue.record("The finished list was asked for a page the stub does not have")
            return PolymarketClosedPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
        }

        return try page.get()
    }

    private func nextOpenPage(cursor: String?) -> Result<PolymarketPositionsPage, Error>? {
        guard !openPagesByCursor.isEmpty else {
            return openPages[safe: openCursors.count - 1] ?? openPages.last
        }

        guard var queue = openPagesByCursor[cursor], let next = queue.first else { return nil }

        if queue.count > 1 {
            queue.removeFirst()
            openPagesByCursor[cursor] = queue
        }

        return next
    }
}

private final class MyPositionsRoutableSpy: PolymarketMyPositionsRoutable {
    private(set) var redeemed: [PolymarketPosition] = []
    private(set) var detailed: [PolymarketPosition] = []
    private(set) var onClaimed: ((PolymarketPosition?) -> Void)?

    func closeMyPositions() {}

    func openPositionDetails(
        position: PolymarketPosition,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        detailed.append(position)
    }

    @MainActor
    func openRedeem(position: PolymarketPosition, onClaimed: @escaping (PolymarketPosition?) -> Void) {
        redeemed.append(position)
        self.onClaimed = onClaimed
    }
}
