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
@Suite("Polymarket my positions")
struct PolymarketMyPositionsViewModelTests {
    // MARK: - Where a tapped row leads

    @Test("A resolved settlement opens the claim screen", arguments: [PolymarketPositionSettlement.won, .lost, .split])
    func resolvedSettlementOpensRedeem(settlement: PolymarketPositionSettlement) async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 1, nextCursor: nil, settlement: settlement)])
        let routable = MyPositionsRoutableSpy()
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: routable)

        try await settle { sut.loadingState == .allDataLoaded }

        sut.openPosition(id: try #require(sut.rows.first).id)

        #expect(routable.redeemed.count == 1)
        #expect(routable.detailed.isEmpty)
    }

    @Test("An unreadable settlement keeps opening the details")
    func unknownSettlementOpensDetails() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 1, nextCursor: nil, settlement: .unknown)])
        let routable = MyPositionsRoutableSpy()
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: routable)

        try await settle { sut.loadingState == .allDataLoaded }

        sut.openPosition(id: try #require(sut.rows.first).id)

        #expect(routable.redeemed.isEmpty)
        #expect(routable.detailed.count == 1)
    }

    @Test("A position still running opens the details")
    func unsettledPositionOpensDetails() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 1, nextCursor: nil)])
        let routable = MyPositionsRoutableSpy()
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: routable)

        try await settle { sut.loadingState == .allDataLoaded }

        sut.openPosition(id: try #require(sut.rows.first).id)

        #expect(routable.redeemed.isEmpty)
        #expect(routable.detailed.count == 1)
    }

    @Test("The first page is asked for without a cursor")
    func firstPageHasNoCursor() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 3, nextCursor: nil)])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded }

        #expect(service.openCursors == [nil])
        #expect(sut.rows.count == 3)
    }

    @Test("The next page is asked for with the cursor the server handed back")
    func nextPageFollowsTheServerCursor() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 20, nextCursor: "c1"),
            Self.openPage(count: 5, nextCursor: nil, firstIndex: 20),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }

        sut.handleViewAction(.loadNextPage)
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(service.openCursors == [nil, "c1"])
        #expect(sut.rows.count == 25)
    }

    @Test("A list the backend has ended is not asked for again")
    func loadMoreStopsAtTheEnd() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 2, nextCursor: nil)])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded }
        sut.handleViewAction(.loadNextPage)

        #expect(service.openCursors == [nil])
    }

    @Test("A filter that swallows whole pages asks in bounded bursts and never claims the list is empty")
    func emptyPagesAreBounded() async throws {
        let pages = (0 ..< 10).map { _ in Self.openPage(count: 5, nextCursor: "more") }
        let service = PolymarketPositionsServiceStub(openPages: pages)
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded || sut.loadingState == .loaded }

        sut.handleViewAction(.selectFilter(.won))
        try await settle { sut.loadingState == .loaded }

        #expect(sut.rows.isEmpty)
        #expect(sut.loadingState != .empty)
        #expect(service.openCursors.count <= 5)
    }

    @Test("A filter that swallows what is loaded keeps walking rather than stranding the list")
    func filterResumesTheWalk() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 2, nextCursor: "c1"),
            Self.openPage(count: 2, nextCursor: nil, settlement: .won, firstIndex: 2),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }
        sut.handleViewAction(.selectFilter(.won))
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(sut.rows.count == 2)
        #expect(service.openCursors == [nil, "c1"])
    }

    @Test("Switching the tab drops a filter that cannot match anything on the other list")
    func tabSwitchResetsTheFilter() async throws {
        let service = PolymarketPositionsServiceStub(
            openPages: [Self.openPage(count: 1, nextCursor: nil)],
            closedPages: [Self.closedPage(count: 1, nextCursor: nil)]
        )
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded }
        sut.handleViewAction(.selectFilter(.active))
        sut.tab = .finished
        try await settle { sut.loadingState == .allDataLoaded }

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
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }

        sut.handleViewAction(.loadNextPage)
        try await settle { sut.loadingState == .allDataLoaded }

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
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }

        sut.handleViewAction(.loadNextPage)
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(service.openCursors == [nil, "c1", nil])
        #expect(sut.rows.count == 2)
    }

    @Test("A first page that fails offers a retry, and the retry brings the list back")
    func theFirstFailureIsRecoverable() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            .failure(TestError.refused),
            Self.openPage(count: 2, nextCursor: nil),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .error }
        #expect(sut.rows.isEmpty)

        sut.handleViewAction(.retry)
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(sut.rows.count == 2)
    }

    @Test("A failure deeper in the list keeps what is already on screen")
    func aLaterFailureKeepsTheRows() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 2, nextCursor: "c1"),
            .failure(TestError.refused),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }

        sut.handleViewAction(.loadNextPage)
        try await settle { sut.loadingState == .paginationError }

        #expect(sut.rows.count == 2)
    }

    @Test("The empty copy separates a list with nothing in it from a filter that found nothing")
    func emptyCopyFollowsTheCause() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 1, nextCursor: nil)])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded }
        #expect(sut.emptyMessage == PolymarketPositionsTab.active.emptyMessage)

        sut.handleViewAction(.selectFilter(.won))
        try await settle { sut.loadingState == .empty }
        #expect(sut.emptyMessage != PolymarketPositionsTab.active.emptyMessage)
    }

    // MARK: - Polling

    @Test("Polling asks again only for the pages on screen, each with the cursor it was loaded with")
    func pollingRefreshesVisiblePagesWithTheirCursors() async throws {
        let clock = PositionsClock()
        let service = PolymarketPositionsServiceStub(openPagesByCursor: [
            nil: [Self.openPage(count: 2, nextCursor: "c1")],
            "c1": [
                Self.openPage(count: 2, nextCursor: "c2", firstIndex: 2),
                Self.openPage(count: 2, nextCursor: "c2", firstIndex: 2, emptiedIndex: 3),
            ],
            "c2": [Self.openPage(count: 2, nextCursor: nil, firstIndex: 4)],
        ])
        let sut = Self.makeSUT(service: service, clock: clock)

        try await settle { sut.loadingState == .loaded }
        sut.handleViewAction(.loadNextPage)
        try await settle { sut.loadingState == .loaded && sut.rows.count == 4 }
        sut.handleViewAction(.loadNextPage)
        try await settle { sut.loadingState == .allDataLoaded }

        clock.advance(by: 21)
        sut.handleViewAction(.onRowVisibilityChange(id: "0x3/1", isVisible: true))

        try await settle { sut.rows.count == 5 }

        #expect(service.openCursors == [nil, "c1", "c2", "c1"])
        #expect(!sut.rows.map(\.id).contains("0x3/1"))
    }

    @Test("A page refreshed recently or kept off screen is not asked for")
    func freshOrHiddenPagesAreNotRefreshed() async throws {
        let clock = PositionsClock()
        let service = PolymarketPositionsServiceStub(openPagesByCursor: [nil: [Self.openPage(count: 2, nextCursor: nil)]])
        let sut = Self.makeSUT(service: service, clock: clock)

        try await settle { sut.loadingState == .allDataLoaded }

        sut.handleViewAction(.onRowVisibilityChange(id: "0x0/1", isVisible: true))
        try await Self.letTicksRun()

        sut.handleViewAction(.onRowVisibilityChange(id: "0x0/1", isVisible: false))
        clock.advance(by: 21)
        sut.handleViewAction(.onRowVisibilityChange(id: "elsewhere", isVisible: true))
        try await Self.letTicksRun()

        #expect(service.openCursors == [nil])

        sut.handleViewAction(.onRowVisibilityChange(id: "0x0/1", isVisible: true))
        try await settle { service.openCursors == [nil, nil] }
    }

    @Test("A reload while a page is being refreshed drops the late answer")
    func reloadDropsTheStalePage() async throws {
        let clock = PositionsClock()
        let service = PolymarketPositionsServiceStub(openPagesByCursor: [
            nil: [
                Self.openPage(count: 2, nextCursor: nil),
                Self.openPage(count: 2, nextCursor: nil, emptiedIndex: 0),
                Self.openPage(count: 2, nextCursor: nil),
            ],
        ])
        let sut = Self.makeSUT(service: service, clock: clock)

        try await settle { sut.loadingState == .allDataLoaded }

        service.hold(cursor: nil)
        clock.advance(by: 21)
        sut.handleViewAction(.onRowVisibilityChange(id: "0x0/1", isVisible: true))
        try await settle { service.openCursors.count == 2 }

        service.releaseHeld()
        sut.reload()
        try await settle { service.answeredCount == 3 && sut.loadingState == .allDataLoaded }
        try await Self.letTicksRun()

        #expect(sut.rows.map(\.id) == ["0x0/1", "0x1/1"])
    }

    @Test("A refreshed page whose cursor the backend refuses keeps the rows and is not asked for again")
    func refreshWithRejectedCursorKeepsTheRows() async throws {
        let clock = PositionsClock()
        let service = PolymarketPositionsServiceStub(openPagesByCursor: [
            nil: [Self.openPage(count: 2, nextCursor: "c1")],
            "c1": [
                Self.openPage(count: 2, nextCursor: nil, firstIndex: 2),
                .failure(PolymarketAPIError.http(statusCode: 400, problemDetail: nil)),
            ],
        ])
        let sut = Self.makeSUT(service: service, clock: clock)

        try await settle { sut.loadingState == .loaded }
        sut.handleViewAction(.loadNextPage)
        try await settle { sut.loadingState == .allDataLoaded }

        clock.advance(by: 21)
        sut.handleViewAction(.onRowVisibilityChange(id: "0x2/1", isVisible: true))
        try await settle { service.answeredCount == 3 }
        try await Self.letTicksRun()

        #expect(service.openCursors == [nil, "c1", "c1"])
        #expect(sut.rows.count == 4)
        #expect(sut.loadingState == .allDataLoaded)

        clock.advance(by: 21)
        sut.handleViewAction(.onRowVisibilityChange(id: "0x3/1", isVisible: true))
        try await Self.letTicksRun()

        #expect(service.openCursors == [nil, "c1", "c1"])
    }

    // MARK: - Claim availability

    @Test("A resolved position of a market version this build does not know opens the details, not the claim")
    func unknownVersionHasNoClaim() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 1, nextCursor: nil, settlement: .won, version: .unknown("v3")),
        ])
        let routable = MyPositionsRoutableSpy()
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: routable)

        try await settle { sut.loadingState == .allDataLoaded }

        sut.openPosition(id: try #require(sut.rows.first).id)

        #expect(routable.redeemed.isEmpty)
        #expect(routable.detailed.count == 1)
    }
}

// MARK: - Helpers

private extension PolymarketMyPositionsViewModelTests {
    static func makeSUT(service: PolymarketPositionsServiceStub, clock: PositionsClock) -> PolymarketMyPositionsViewModel {
        PolymarketMyPositionsViewModel(
            tab: .active,
            positionsService: service,
            coordinator: nil,
            notificationCenter: NotificationCenter(),
            now: { clock.now },
            visibilitySettleDelay: 0
        )
    }

    static func letTicksRun() async throws {
        for _ in 0 ..< 20 {
            await Task.yield()
        }

        try await Task.sleep(nanoseconds: 50_000_000)
    }

    static func openPage(
        count: Int,
        nextCursor: String?,
        settlement: PolymarketPositionSettlement? = nil,
        firstIndex: Int = 0,
        emptiedIndex: Int? = nil,
        version: PolymarketMarketVersion? = .v1
    ) -> Result<PolymarketPositionsPage, Error> {
        .success(PolymarketPositionsPage(
            positions: (0 ..< count).map { index in
                PolymarketPosition(
                    conditionId: "0x\(firstIndex + index)",
                    assetId: "1",
                    marketId: "3",
                    version: version,
                    eventId: "4",
                    eventTitle: "Event",
                    title: "Question",
                    iconURL: nil,
                    endDate: nil,
                    outcome: "Yes",
                    outcomeIndex: 0,
                    size: firstIndex + index == emptiedIndex ? 0 : 1,
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
            },
            receivedCount: count,
            nextCursor: nextCursor
        ))
    }

    static func closedPage(
        count: Int,
        nextCursor: String?,
        firstIndex: Int = 0
    ) -> Result<PolymarketClosedPositionsPage, Error> {
        .success(PolymarketClosedPositionsPage(
            positions: (0 ..< count).map { index in
                PolymarketClosedPosition(
                    conditionId: "0x\(firstIndex + index)",
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

private final class PolymarketPositionsServiceStub: PolymarketPositionsService, Sendable {
    private struct State {
        var openCursors: [String?] = []
        var closedCursors: [String?] = []
        var answeredCount = 0
        var heldCursors: Set<String?> = []
        var waiting: [CheckedContinuation<Void, Never>] = []
        var openPagesByCursor: [String?: [Result<PolymarketPositionsPage, Error>]]
    }

    private let openPages: [Result<PolymarketPositionsPage, Error>]
    private let closedPages: [Result<PolymarketClosedPositionsPage, Error>]
    private let state: OSAllocatedUnfairLock<State>

    init(
        openPages: [Result<PolymarketPositionsPage, Error>] = [],
        closedPages: [Result<PolymarketClosedPositionsPage, Error>] = [],
        openPagesByCursor: [String?: [Result<PolymarketPositionsPage, Error>]] = [:]
    ) {
        self.openPages = openPages
        self.closedPages = closedPages
        state = OSAllocatedUnfairLock(initialState: State(openPagesByCursor: openPagesByCursor))
    }

    var openCursors: [String?] {
        state.withLock { $0.openCursors }
    }

    var closedCursors: [String?] {
        state.withLock { $0.closedCursors }
    }

    var answeredCount: Int {
        state.withLock { $0.answeredCount }
    }

    func hold(cursor: String?) {
        state.withLock { _ = $0.heldCursors.insert(cursor) }
    }

    func releaseHeld() {
        let waiting = state.withLock { state in
            state.heldCursors = []
            defer { state.waiting = [] }
            return state.waiting
        }

        waiting.forEach { $0.resume() }
    }

    func activePositions(limit: Int) async throws -> PolymarketPositionsPage {
        guard let first = openPages.first else {
            return PolymarketPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
        }

        let page = try first.get()

        return PolymarketPositionsPage(
            positions: page.positions.filter { $0.settlement == nil },
            receivedCount: page.receivedCount,
            nextCursor: page.nextCursor
        )
    }

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition? {
        nil
    }

    func awaitPosition(conditionId: String, assetId: String, changedFrom shares: Decimal?) async throws -> PolymarketPosition? {
        nil
    }

    func openPositions(limit: Int, cursor: String?) async throws -> PolymarketPositionsPage {
        let (page, isHeld) = state.withLock { state in
            state.openCursors.append(cursor)
            return (Self.nextOpenPage(cursor: cursor, state: &state, openPages: openPages), state.heldCursors.contains(cursor))
        }

        if isHeld {
            await withCheckedContinuation { continuation in
                let resumeNow = state.withLock { state in
                    guard state.heldCursors.contains(cursor) else { return true }

                    state.waiting.append(continuation)
                    return false
                }

                if resumeNow {
                    continuation.resume()
                }
            }
        }

        defer { state.withLock { $0.answeredCount += 1 } }

        guard let page else {
            Issue.record("The open list was asked for a page the stub does not have")
            return PolymarketPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
        }

        return try page.get()
    }

    func closedPositions(limit: Int, cursor: String?) async throws -> PolymarketClosedPositionsPage {
        let index = state.withLock { state in
            state.closedCursors.append(cursor)
            return state.closedCursors.count - 1
        }

        guard let page = closedPages[safe: index] ?? closedPages.last else {
            Issue.record("The finished list was asked for a page the stub does not have")
            return PolymarketClosedPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
        }

        return try page.get()
    }

    private static func nextOpenPage(
        cursor: String?,
        state: inout State,
        openPages: [Result<PolymarketPositionsPage, Error>]
    ) -> Result<PolymarketPositionsPage, Error>? {
        guard !state.openPagesByCursor.isEmpty else {
            return openPages[safe: state.openCursors.count - 1] ?? openPages.last
        }

        guard var queue = state.openPagesByCursor[cursor], let next = queue.first else { return nil }

        if queue.count > 1 {
            queue.removeFirst()
            state.openPagesByCursor[cursor] = queue
        }

        return next
    }
}

// MARK: - Doubles

private final class MyPositionsRoutableSpy: PolymarketMyPositionsRoutable {
    private struct Opened {
        var redeemed: [PolymarketPosition] = []
        var detailed: [PolymarketPosition] = []
    }

    private let opened = OSAllocatedUnfairLock(initialState: Opened())

    var redeemed: [PolymarketPosition] {
        opened.withLock { $0.redeemed }
    }

    var detailed: [PolymarketPosition] {
        opened.withLock { $0.detailed }
    }

    func closeMyPositions() {}

    func openPositionDetails(
        position: PolymarketPosition,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        opened.withLock { $0.detailed.append(position) }
    }

    @MainActor
    func openRedeem(position: PolymarketPosition, onClaimed: @escaping (PolymarketPosition?) -> Void) {
        opened.withLock { $0.redeemed.append(position) }
    }
}
