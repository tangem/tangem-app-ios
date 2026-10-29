//
//  PolymarketActivityViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket history screen", .timeLimit(.minutes(1)))
@MainActor
struct PolymarketActivityViewModelTests {
    @Test("The first page shows its rows and asks for a deposit scan")
    func loadsFirstPage() async throws {
        let service = PolymarketActivityServiceStub()
        service.pages[nil] = .success(.init(records: [.withdrawal(id: "1")], receivedCount: 1, nextCursor: nil))

        let sut = PolymarketActivityViewModel(activityService: service, coordinator: nil)

        try await service.reconciled.next()
        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(sut.sections.flatMap(\.rows).map(\.id) == ["1"])
    }

    @Test("A rejected request stops on an error that only a tap retries")
    func rejectedRequest() async throws {
        let service = PolymarketActivityServiceStub()
        service.pages[nil] = .failure(PolymarketAPIError.http(statusCode: 403, problemDetail: nil))

        let sut = PolymarketActivityViewModel(activityService: service, coordinator: nil)

        await Self.loadingState(of: sut, becomes: .error(.rejected(statusCode: 403)))

        service.pages[nil] = .success(.init(records: [.withdrawal(id: "1")], receivedCount: 1, nextCursor: nil))
        sut.handleViewAction(.retry)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(sut.sections.flatMap(\.rows).map(\.id) == ["1"])
    }

    @Test("The next page continues from the cursor and merges a claim split across pages")
    func pagesAndMergesClaims() async throws {
        let service = PolymarketActivityServiceStub()
        service.pages[nil] = .success(.init(records: [.claim(id: "1", amount: 4, result: .won)], receivedCount: 1, nextCursor: "next"))
        service.pages["next"] = .success(.init(records: [.claim(id: "2", amount: 0, result: .lost)], receivedCount: 1, nextCursor: nil))

        let sut = PolymarketActivityViewModel(activityService: service, coordinator: nil)

        await Self.loadingState(of: sut, becomes: .loaded)
        sut.handleViewAction(.loadNextPage)
        await Self.loadingState(of: sut, becomes: .allDataLoaded)

        #expect(service.requestedCursors == [nil, "next"])
        #expect(sut.sections.flatMap(\.rows).map(\.id) == ["1"])
    }

    @Test("Tapping a claim opens its merged details")
    func opensMergedClaim() async throws {
        let service = PolymarketActivityServiceStub()
        service.pages[nil] = .success(.init(
            records: [.claim(id: "1", amount: 0, result: .lost), .claim(id: "2", amount: 6, result: .won)],
            receivedCount: 2,
            nextCursor: nil
        ))
        let routable = PolymarketActivityRoutableSpy()

        let sut = PolymarketActivityViewModel(activityService: service, coordinator: routable)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        sut.handleViewAction(.rowTapped(id: "1"))

        #expect(routable.openedRecords.first?.amount == 6)
        #expect(routable.openedRecords.first?.redeemResult == .won)
    }

    @Test("A rejected next page keeps the cursor and the rows, and the footer retries the same page")
    func rejectedNextPageKeepsTheCursor() async throws {
        let service = PolymarketActivityServiceStub()
        service.pages[nil] = .success(.init(records: [.withdrawal(id: "1")], receivedCount: 1, nextCursor: "next"))
        service.pages["next"] = .failure(PolymarketAPIError.http(statusCode: 400, problemDetail: nil))

        let sut = PolymarketActivityViewModel(activityService: service, coordinator: nil)

        await Self.loadingState(of: sut, becomes: .loaded)
        sut.handleViewAction(.loadNextPage)
        await Self.loadingState(of: sut, becomes: .paginationError)
        #expect(sut.sections.flatMap(\.rows).map(\.id) == ["1"])

        service.pages["next"] = .success(.init(records: [.withdrawal(id: "2")], receivedCount: 1, nextCursor: nil))
        sut.handleViewAction(.retryNextPage)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(service.requestedCursors == [nil, "next", "next"])
        #expect(sut.sections.flatMap(\.rows).map(\.id) == ["1", "2"])
    }

    @Test("A next page asked for while the first page refreshes is loaded once the refresh settles")
    func nextPageAskedDuringRefreshIsLoadedAfterIt() async throws {
        let service = PolymarketActivityServiceStub()
        service.pages[nil] = .success(.init(records: [.withdrawal(id: "1")], receivedCount: 1, nextCursor: "next"))
        service.pages["next"] = .success(.init(records: [.withdrawal(id: "2")], receivedCount: 1, nextCursor: nil))

        let sut = PolymarketActivityViewModel(activityService: service, coordinator: nil)

        await Self.loadingState(of: sut, becomes: .loaded)

        let firstPage = PolymarketTestGate()
        service.firstPageGate = firstPage
        let refresh = Task { await sut.refresh() }
        try await firstPage.entered.next()

        sut.handleViewAction(.loadNextPage)
        #expect(sut.loadingState == .loaded)

        firstPage.open()
        await refresh.value

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(service.requestedCursors == [nil, nil, "next"])
        #expect(sut.sections.flatMap(\.rows).map(\.id) == ["1", "2"])
    }
}

// MARK: - Helpers

private extension PolymarketActivityViewModelTests {
    static func loadingState(of sut: PolymarketActivityViewModel, becomes state: PolymarketActivityViewModel.LoadingState) async {
        _ = await sut.$loadingState.firstValue { $0 == state }
    }
}

private extension PolymarketActivityRecord {
    static func withdrawal(id: String) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: id,
            type: .withdraw,
            occurredAt: Date(),
            amount: 1,
            transactionHash: "0x\(id)",
            market: nil,
            order: nil,
            redeemResult: nil
        )
    }

    static func claim(id: String, amount: Decimal, result: PolymarketRedeemResult) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: id,
            type: .redeem,
            occurredAt: Date(),
            amount: amount,
            transactionHash: "0xclaim",
            market: PolymarketActivityMarket(
                conditionId: "c1",
                outcomeIndex: result == .won ? 0 : 1,
                shares: amount,
                outcome: result == .won ? "Yes" : "No",
                marketId: nil,
                slug: nil,
                title: "Market",
                iconURL: nil,
                imageURL: nil,
                endDate: nil,
                isNegRisk: false,
                event: nil
            ),
            order: nil,
            redeemResult: result
        )
    }
}
