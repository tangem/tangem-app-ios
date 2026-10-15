//
//  PolymarketPositionsBlockViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import UIKit
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket positions block")
struct PolymarketPositionsBlockViewModelTests {
    // MARK: - What the block shows

    @Test("A wallet that never had a position keeps the block hidden while loading and after an empty answer")
    func newcomerSeesNothing() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page([])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        #expect(context.sut.content == .hidden)

        try await settle { service.activeRequests == 1 }
        try await drain()

        #expect(context.sut.content == .hidden)
        #expect(!context.sut.hasFinishedPositions)
        #expect(!context.presenceStore.hadPositions(userWalletId: Self.userWalletId))
    }

    @Test("A wallet that had positions sees a skeleton until the list arrives")
    func returningUserSeesSkeleton() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service, hadPositions: true)

        #expect(context.sut.content == .skeleton)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }
    }

    @Test("The block shows three positions and offers the rest when there are more")
    func showsThreeAndOffersTheRest() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b", "c", "d"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) != nil }

        #expect(Self.rowIDs(context.sut.content) == ["a/1", "b/1", "c/1"])
        #expect(Self.showsViewAll(context.sut.content) == true)
    }

    @Test("Finished positions light up the badge and mark the wallet as having had positions")
    func finishedPositionsShowTheBadge() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page([])], finished: [.success(true)])
        let context = Self.makeSUT(service: service)

        try await settle { context.sut.hasFinishedPositions }

        #expect(context.sut.content == .noActivePositions(showsViewAll: false))
        #expect(context.presenceStore.hadPositions(userWalletId: Self.userWalletId))
    }

    // MARK: - Failures

    @Test("A failed first load offers a retry, and the retry brings the list back")
    func failedLoadOffersRetry() async throws {
        let service = PositionsBlockServiceStub(
            active: [.failure(TestError.refused), Self.page(["a"])],
            finished: [.failure(TestError.refused), .success(false)]
        )
        let context = Self.makeSUT(service: service)

        try await settle { context.sut.content == .failed }

        context.sut.handleViewAction(.retry)

        #expect(context.sut.content == .skeleton)
        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }
    }

    @Test("An empty list with an unknown history offers a retry instead of hiding the block")
    func unknownHistoryWithoutPositionsFails() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page([])], finished: [.failure(TestError.refused)])
        let context = Self.makeSUT(service: service)

        try await settle { context.sut.content == .failed }
    }

    @Test("A failure after the list has loaded keeps what is on screen")
    func laterFailureKeepsTheList() async throws {
        let service = PositionsBlockServiceStub(
            active: [Self.page(["a"]), .failure(TestError.refused)],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }

        await context.refreshCenter.refresh(.full)

        try await settle { service.activeRequests == 2 }
        try await drain()
        #expect(Self.rowIDs(context.sut.content) == ["a/1"])
    }

    // MARK: - Refresh

    @Test("A balance refresh leaves the positions alone, a full one reloads them")
    func onlyAFullRefreshReloads() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"]), Self.page(["b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }

        await context.refreshCenter.refresh(.balance)
        #expect(service.activeRequests == 1)

        await context.refreshCenter.refresh(.full)
        try await settle { Self.rowIDs(context.sut.content) == ["b/1"] }
    }

    @Test("An account funds refresh leaves the positions alone")
    func accountFundsRefreshLeavesPositionsAlone() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }

        await context.refreshCenter.refresh(.accountFunds)
        try await drain()

        #expect(service.activeRequests == 1)
    }

    @Test("A full refresh after a failure keeps the error on screen instead of flashing a skeleton")
    func refreshAfterFailureStaysQuiet() async throws {
        let service = PositionsBlockServiceStub(
            active: [.failure(TestError.refused), .failure(TestError.refused)],
            finished: [.failure(TestError.refused)]
        )
        let context = Self.makeSUT(service: service, hadPositions: true)

        try await settle { context.sut.content == .failed }

        await context.refreshCenter.refresh(.full)

        #expect(context.sut.content == .failed)
        try await settle { service.activeRequests >= 2 }
        #expect(context.sut.content == .failed)
    }

    @Test("Going to background drops the load in flight")
    func backgroundCancelsTheLoadInFlight() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"]), Self.page(["b"])], finished: [.success(false)])
        service.slowActiveRequests = [1]
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }

        await context.refreshCenter.refresh(.full)
        try await settle { service.activeRequests == 2 }

        context.notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try await Task.sleep(nanoseconds: PositionsBlockServiceStub.slowDelay * 2)

        #expect(Self.rowIDs(context.sut.content) == ["a/1"])
    }

    @Test("Coming back from background reloads the list")
    func foregroundReloads() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"]), Self.page(["b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }

        context.notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        context.notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        try await settle { Self.rowIDs(context.sut.content) == ["b/1"] }
    }

    // MARK: - Trades and claims

    @Test("A claimed position leaves the list even when the reload still hands it back")
    func claimedPositionLeaves() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1", "b/1"] }

        context.activityHandler.claimed(Self.position("a"))

        try await settle { Self.rowIDs(context.sut.content) == ["b/1"] }

        await context.refreshCenter.refresh(.full)
        try await settle { service.activeRequests == 3 }
        try await drain()

        #expect(Self.rowIDs(context.sut.content) == ["b/1"])
    }

    @Test("A sold-out position leaves the list even when the reload still hands it back")
    func soldOutPositionLeaves() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1", "b/1"] }

        context.activityHandler.orderPlaced(awaiting: Task { Self.position("a", size: 0) })

        try await settle { Self.rowIDs(context.sut.content) == ["b/1"] }

        await context.refreshCenter.refresh(.full)
        try await settle { service.activeRequests == 3 }
        try await drain()

        #expect(Self.rowIDs(context.sut.content) == ["b/1"])
    }

    @Test("A partial sale updates the row in place")
    func partialSaleUpdatesTheRow() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1", "b/1"] }

        context.activityHandler.orderPlaced(awaiting: Task { Self.position("a", size: 2, title: "Updated") })

        try await settle { Self.rowQuestions(context.sut.content)?.first == "Updated" }
        #expect(Self.rowIDs(context.sut.content) == ["a/1", "b/1"])
    }

    @Test("A claim from the claim screen reaches the block through the router callback")
    func claimThroughRouterLeavesTheList() async throws {
        let service = PositionsBlockServiceStub(
            active: [.success(PolymarketPositionsPage(
                positions: [Self.position("a", isRedeemable: true), Self.position("b")],
                receivedCount: 2,
                hasNext: false
            ))],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1", "b/1"] }

        context.sut.handleViewAction(.openPositionDetails(id: "a/1"))
        context.routable.lastOnClaimed?(Self.position("a"))

        try await settle { Self.rowIDs(context.sut.content) == ["b/1"] }
    }

    @Test("A claim from my positions reaches the block through the router callback")
    func claimFromMyPositionsLeavesTheList() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1", "b/1"] }

        context.sut.handleViewAction(.openMyPositions(.active))
        context.routable.lastOnClaimed?(Self.position("a"))

        try await settle { Self.rowIDs(context.sut.content) == ["b/1"] }
    }

    @Test("A trade from my positions reaches the block through the router callback")
    func tradeFromMyPositionsLeavesTheList() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1", "b/1"] }

        context.sut.handleViewAction(.openMyPositions(.active))
        context.routable.lastOnOrderPlaced?(Task { Self.position("a", size: 0) })

        try await settle { Self.rowIDs(context.sut.content) == ["b/1"] }
    }

    @Test("A trade from the position details reaches the block through the router callback")
    func tradeThroughRouterLeavesTheList() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1", "b/1"] }

        context.sut.handleViewAction(.openPositionDetails(id: "a/1"))
        context.routable.lastOnOrderPlaced?(Task { Self.position("a", size: 0) })

        try await settle { Self.rowIDs(context.sut.content) == ["b/1"] }
    }

    // MARK: - Navigation

    @Test("A running position opens its details, a redeemable one opens the claim")
    func tappedRowLeadsWhereItShould() async throws {
        let service = PositionsBlockServiceStub(
            active: [.success(PolymarketPositionsPage(
                positions: [Self.position("a"), Self.position("b", isRedeemable: true)],
                receivedCount: 2,
                hasNext: false
            ))],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1", "b/1"] }

        context.sut.handleViewAction(.openPositionDetails(id: "a/1"))
        context.sut.handleViewAction(.openPositionDetails(id: "b/1"))

        #expect(context.routable.detailedIDs == ["a/1"])
        #expect(context.routable.redeemedIDs == ["b/1"])
    }

    @Test("A settled position opens the claim even before it turns redeemable")
    func settledRowOpensTheClaim() async throws {
        let service = PositionsBlockServiceStub(
            active: [.success(PolymarketPositionsPage(
                positions: [Self.position("a", settlement: .won)],
                receivedCount: 1,
                hasNext: false
            ))],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }

        context.sut.handleViewAction(.openPositionDetails(id: "a/1"))

        #expect(context.routable.detailedIDs.isEmpty)
        #expect(context.routable.redeemedIDs == ["a/1"])
    }

    @Test("View all opens the active tab and the finished badge opens the finished one")
    func viewAllAndBadgeOpenTheirTabs() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"])], finished: [.success(true)])
        let context = Self.makeSUT(service: service)

        try await settle { Self.rowIDs(context.sut.content) == ["a/1"] }

        context.sut.handleViewAction(.openMyPositions(.active))
        context.sut.handleViewAction(.openMyPositions(.finished))

        #expect(context.routable.openedTabs == [.active, .finished])
    }
}

// MARK: - Helpers

private extension PolymarketPositionsBlockViewModelTests {
    struct Context {
        let sut: PolymarketPositionsBlockViewModel
        let presenceStore: PolymarketAccountPresenceStoreStub
        let refreshCenter: PolymarketMainRefreshCenter
        let activityHandler: PolymarketMainActivityHandler
        let routable: PositionsBlockRoutableSpy
        let notificationCenter: NotificationCenter
    }

    static let userWalletId = UserWalletId(value: Data([0x01, 0x02, 0x03]))

    static func makeSUT(service: PositionsBlockServiceStub, hadPositions: Bool = false) -> Context {
        let presenceStore = PolymarketAccountPresenceStoreStub(positions: hadPositions)
        let refreshCenter = PolymarketMainRefreshCenter()
        let activityHandler = PolymarketMainActivityHandler(
            fundsArrivalTracker: PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher()),
            refreshCenter: refreshCenter
        )
        let routable = PositionsBlockRoutableSpy()
        let notificationCenter = NotificationCenter()

        let sut = PolymarketPositionsBlockViewModel(
            positionsService: service,
            presenceStore: presenceStore,
            userWalletId: userWalletId,
            refreshCenter: refreshCenter,
            activityHandler: activityHandler,
            routable: routable,
            notificationCenter: notificationCenter
        )

        return Context(
            sut: sut,
            presenceStore: presenceStore,
            refreshCenter: refreshCenter,
            activityHandler: activityHandler,
            routable: routable,
            notificationCenter: notificationCenter
        )
    }

    static func rowIDs(_ content: PolymarketPositionsBlockViewModel.Content) -> [String]? {
        guard case .positions(let models, _) = content else { return nil }

        return models.map(\.id)
    }

    static func rowQuestions(_ content: PolymarketPositionsBlockViewModel.Content) -> [String]? {
        guard case .positions(let models, _) = content else { return nil }

        return models.map(\.question)
    }

    static func showsViewAll(_ content: PolymarketPositionsBlockViewModel.Content) -> Bool? {
        guard case .positions(_, let showsViewAll) = content else { return nil }

        return showsViewAll
    }

    static func page(_ conditionIds: [String]) -> Result<PolymarketPositionsPage, Error> {
        .success(PolymarketPositionsPage(
            positions: conditionIds.map { position($0) },
            receivedCount: conditionIds.count,
            hasNext: false
        ))
    }

    static func position(
        _ conditionId: String,
        size: Decimal = 1,
        isRedeemable: Bool = false,
        settlement: PolymarketPositionSettlement? = nil,
        title: String = "Question"
    ) -> PolymarketPosition {
        PolymarketPosition(
            conditionId: conditionId,
            assetId: "1",
            marketId: "3",
            eventId: "4",
            eventTitle: "Event",
            title: title,
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
            isRedeemable: isRedeemable,
            isNegRisk: false,
            isAcceptingOrders: true,
            isLive: false,
            resolutionStatus: .open,
            settlement: settlement
        )
    }
}

// MARK: - Doubles

private enum TestError: Error {
    case refused
}

private final class PositionsBlockServiceStub: PolymarketPositionsService {
    private struct Script {
        var active: [Result<PolymarketPositionsPage, Error>]
        var finished: [Result<Bool, Error>]
        var activeRequests = 0
        var finishedRequests = 0
    }

    static let slowDelay: UInt64 = 200_000_000

    var slowActiveRequests: Set<Int> = []

    private let script: OSAllocatedUnfairLock<Script>

    var activeRequests: Int {
        script.withLock { $0.activeRequests }
    }

    init(active: [Result<PolymarketPositionsPage, Error>], finished: [Result<Bool, Error>]) {
        script = OSAllocatedUnfairLock(initialState: Script(active: active, finished: finished))
    }

    func activePositions(limit: Int) async throws -> PolymarketPositionsPage {
        let (index, result) = script.withLock { script in
            let index = script.activeRequests
            script.activeRequests += 1
            return (index, script.active[safe: index] ?? script.active.last)
        }

        if slowActiveRequests.contains(index) {
            try await Task.sleep(nanoseconds: Self.slowDelay)
        }

        return try result?.get() ?? PolymarketPositionsPage(positions: [], receivedCount: 0, hasNext: false)
    }

    func closedPositions(
        sort: PolymarketClosedPositionsRequest.Sort,
        ascending: Bool,
        limit: Int,
        offset: Int
    ) async throws -> PolymarketClosedPositionsPage {
        let exists = try script.withLock { script in
            let result = script.finished[safe: script.finishedRequests] ?? script.finished.last
            script.finishedRequests += 1
            return result
        }?.get() ?? false

        return PolymarketClosedPositionsPage(
            positions: exists ? [Self.closedPosition] : [],
            receivedCount: exists ? 1 : 0,
            hasNext: false
        )
    }

    func openPositions(
        sort: PolymarketPositionsRequest.Sort,
        ascending: Bool,
        limit: Int,
        offset: Int
    ) async throws -> PolymarketPositionsPage {
        PolymarketPositionsPage(positions: [], receivedCount: 0, hasNext: false)
    }

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition? {
        nil
    }

    func awaitPosition(conditionId: String, assetId: String, changedFrom shares: Decimal?) async throws -> PolymarketPosition? {
        nil
    }

    private static let closedPosition = PolymarketClosedPosition(
        conditionId: "0xclosed",
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
}

private final class PositionsBlockRoutableSpy: PolymarketPositionsBlockRoutable {
    private(set) var detailedIDs: [String] = []
    private(set) var redeemedIDs: [String] = []
    private(set) var openedTabs: [PolymarketPositionsTab] = []
    private(set) var lastOnOrderPlaced: (@MainActor (PolymarketOrderIndexing) -> Void)?
    private(set) var lastOnClaimed: ((PolymarketPosition?) -> Void)?

    func openMyPositions(
        tab: PolymarketPositionsTab,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onClaimed: @escaping (PolymarketPosition?) -> Void
    ) {
        openedTabs.append(tab)
        lastOnOrderPlaced = onOrderPlaced
        lastOnClaimed = onClaimed
    }

    func openRedeem(position: PolymarketPosition, onClaimed: @escaping (PolymarketPosition?) -> Void) {
        redeemedIDs.append(position.id)
        lastOnClaimed = onClaimed
    }

    func openPositionDetails(
        position: PolymarketPosition,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        detailedIDs.append(position.id)
        lastOnOrderPlaced = onOrderPlaced
    }
}
