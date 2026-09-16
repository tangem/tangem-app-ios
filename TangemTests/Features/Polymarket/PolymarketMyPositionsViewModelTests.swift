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
    @Test("The first page is asked for from the start of the list")
    func firstPageStartsAtZero() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 3, hasNext: false)])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded }

        #expect(service.openOffsets == [0])
        #expect(sut.rows.count == 3)
    }

    @Test("The next page starts where the server left off, not where the filter did")
    func offsetFollowsTheServer() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 20, hasNext: true),
            Self.openPage(count: 5, hasNext: false, firstIndex: 20),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }

        sut.handleViewAction(.loadMore)
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(service.openOffsets == [0, 20])
        #expect(sut.rows.count == 25)
    }

    @Test("A list the backend has ended is not asked for again")
    func loadMoreStopsAtTheEnd() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 2, hasNext: false)])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded }
        sut.handleViewAction(.loadMore)

        #expect(service.openOffsets == [0])
    }

    @Test("A filter that swallows whole pages asks in bounded bursts and never claims the list is empty")
    func emptyPagesAreBounded() async throws {
        let pages = (0 ..< 10).map { _ in Self.openPage(count: 5, hasNext: true) }
        let service = PolymarketPositionsServiceStub(openPages: pages)
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded || sut.loadingState == .loaded }

        sut.handleViewAction(.filterSelected(.won))
        try await settle { sut.loadingState == .loaded }

        #expect(sut.rows.isEmpty)
        #expect(sut.loadingState != .empty)
        #expect(service.openOffsets.count <= 5)
    }

    @Test("A filter that swallows what is loaded keeps walking rather than stranding the list")
    func filterResumesTheWalk() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 2, hasNext: true),
            Self.openPage(count: 2, hasNext: false, settlement: .won, firstIndex: 2),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }
        sut.handleViewAction(.filterSelected(.won))
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(sut.rows.count == 2)
        #expect(service.openOffsets == [0, 2])
    }

    @Test("Switching the tab drops a filter that cannot match anything on the other list")
    func tabSwitchResetsTheFilter() async throws {
        let service = PolymarketPositionsServiceStub(
            openPages: [Self.openPage(count: 1, hasNext: false)],
            closedPages: [Self.closedPage(count: 1, hasNext: false)]
        )
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded }
        sut.handleViewAction(.filterSelected(.active))
        sut.tab = .finished
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(sut.filter == .all)
        #expect(sut.rows.count == 1)
    }

    @Test("A row the server repeats between pages is kept once, and the walk still follows the server")
    func repeatedRowsAreKeptOnce() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 3, hasNext: true, firstIndex: 0),
            Self.openPage(count: 3, hasNext: false, firstIndex: 2),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }

        sut.handleViewAction(.loadMore)
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(service.openOffsets == [0, 3])
        #expect(sut.rows.count == 5)
    }

    @Test("A first page that fails offers a retry, and the retry brings the list back")
    func theFirstFailureIsRecoverable() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            .failure(TestError.refused),
            Self.openPage(count: 2, hasNext: false),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .error }
        #expect(sut.rows.isEmpty)

        sut.handleViewAction(.retryTapped)
        try await settle { sut.loadingState == .allDataLoaded }

        #expect(sut.rows.count == 2)
    }

    @Test("A failure deeper in the list keeps what is already on screen")
    func aLaterFailureKeepsTheRows() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [
            Self.openPage(count: 2, hasNext: true),
            .failure(TestError.refused),
        ])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .loaded }

        sut.handleViewAction(.loadMore)
        try await settle { sut.loadingState == .paginationError }

        #expect(sut.rows.count == 2)
    }

    @Test("The empty copy separates a list with nothing in it from a filter that found nothing")
    func emptyCopyFollowsTheCause() async throws {
        let service = PolymarketPositionsServiceStub(openPages: [Self.openPage(count: 1, hasNext: false)])
        let sut = PolymarketMyPositionsViewModel(tab: .active, positionsService: service, coordinator: nil)

        try await settle { sut.loadingState == .allDataLoaded }
        #expect(sut.emptyMessage == PolymarketPositionsTab.active.emptyMessage)

        sut.handleViewAction(.filterSelected(.won))
        try await settle { sut.loadingState == .empty }
        #expect(sut.emptyMessage != PolymarketPositionsTab.active.emptyMessage)
    }
}

// MARK: - Helpers

private extension PolymarketMyPositionsViewModelTests {
    func settle(until isSatisfied: () -> Bool) async throws {
        for _ in 0 ..< 200 {
            if isSatisfied() { return }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        Issue.record("The positions list never settled")
    }

    static func openPage(
        count: Int,
        hasNext: Bool,
        settlement: PolymarketPositionSettlement? = nil,
        firstIndex: Int = 0
    ) -> Result<PolymarketPositionsPage, Error> {
        .success(PolymarketPositionsPage(
            positions: (0 ..< count).map { index in
                PolymarketPosition(
                    conditionId: "0x\(firstIndex + index)",
                    assetId: "1",
                    marketId: "3",
                    eventId: "4",
                    eventTitle: "Event",
                    title: "Question",
                    iconURL: nil,
                    endDate: nil,
                    outcome: "Yes",
                    size: 1,
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
            hasNext: hasNext
        ))
    }

    static func closedPage(
        count: Int,
        hasNext: Bool,
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
                    avgPrice: 1,
                    curPrice: 1,
                    totalBought: 1,
                    realizedPnl: 0,
                    status: .closed
                )
            },
            receivedCount: count,
            hasNext: hasNext
        ))
    }
}

// MARK: - Doubles

private enum TestError: Error {
    case refused
}

private final class PolymarketPositionsServiceStub: PolymarketPositionsService, @unchecked Sendable {
    private(set) var openOffsets: [Int] = []
    private(set) var closedOffsets: [Int] = []

    private let openPages: [Result<PolymarketPositionsPage, Error>]
    private let closedPages: [Result<PolymarketClosedPositionsPage, Error>]

    init(
        openPages: [Result<PolymarketPositionsPage, Error>] = [],
        closedPages: [Result<PolymarketClosedPositionsPage, Error>] = []
    ) {
        self.openPages = openPages
        self.closedPages = closedPages
    }

    func activePositions(limit: Int) async throws -> PolymarketPositionsPage {
        guard let first = openPages.first else {
            return PolymarketPositionsPage(positions: [], receivedCount: 0, hasNext: false)
        }

        let page = try first.get()

        return PolymarketPositionsPage(
            positions: page.positions.filter { $0.settlement == nil },
            receivedCount: page.receivedCount,
            hasNext: page.hasNext
        )
    }

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition? {
        nil
    }

    func awaitPosition(conditionId: String, assetId: String, changedFrom shares: Decimal?) async throws -> PolymarketPosition? {
        nil
    }

    func openPositions(
        sort: PolymarketPositionsRequest.Sort,
        ascending: Bool,
        limit: Int,
        offset: Int
    ) async throws -> PolymarketPositionsPage {
        openOffsets.append(offset)

        guard let page = openPages[safe: openOffsets.count - 1] ?? openPages.last else {
            Issue.record("The open list was asked for a page the stub does not have")
            return PolymarketPositionsPage(positions: [], receivedCount: 0, hasNext: false)
        }

        return try page.get()
    }

    func closedPositions(
        sort: PolymarketClosedPositionsRequest.Sort,
        ascending: Bool,
        limit: Int,
        offset: Int
    ) async throws -> PolymarketClosedPositionsPage {
        closedOffsets.append(offset)

        guard let page = closedPages[safe: closedOffsets.count - 1] ?? closedPages.last else {
            Issue.record("The finished list was asked for a page the stub does not have")
            return PolymarketClosedPositionsPage(positions: [], receivedCount: 0, hasNext: false)
        }

        return try page.get()
    }
}
