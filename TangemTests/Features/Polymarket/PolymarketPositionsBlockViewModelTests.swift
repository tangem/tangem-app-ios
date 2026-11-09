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
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket positions block", .timeLimit(.minutes(1)))
struct PolymarketPositionsBlockViewModelTests {
    // MARK: - What the block shows

    @Test("A wallet that never had a position keeps the block hidden while loading and after an empty answer")
    func newcomerSeesNothing() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page([])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        #expect(context.sut.content == .hidden)

        try await context.log.waitForCount(2)

        #expect(context.log.contents == [.hidden, .hidden])
        #expect(!context.sut.hasFinishedPositions)
        #expect(!context.presenceStore.hadPositions(userWalletId: Self.userWalletId))
    }

    @Test("A wallet that had positions but never showed any sees a single skeleton row")
    func skeletonDefaultsToOneRow() {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service, hadPositions: true)

        #expect(context.sut.content == .skeleton(rowCount: 1))
    }

    @Test("The skeleton has as many rows as the block showed last time")
    func skeletonRemembersTheShownCount() async throws {
        let presenceStore = PolymarketAccountPresenceStoreStub(positions: true)
        let firstService = PositionsBlockServiceStub(active: [Self.page(["a", "b"])], finished: [.success(false)])
        let first = Self.makeSUT(service: firstService, presenceStore: presenceStore)

        try await first.log.waitUntil { Self.rowIDs($0) == ["a/1", "b/1"] }

        #expect(presenceStore.shownPositionsCount(userWalletId: Self.userWalletId) == 2)

        let secondService = PositionsBlockServiceStub(active: [Self.page(["a"])], finished: [.success(false)])
        let second = Self.makeSUT(service: secondService, presenceStore: presenceStore)

        #expect(second.sut.content == .skeleton(rowCount: 2))
    }

    @Test("The block shows three positions and offers the rest when there are more")
    func showsThreeAndOffersTheRest() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b", "c", "d"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)

        try await context.log.waitUntil { Self.rowIDs($0) != nil }

        #expect(Self.rowIDs(context.sut.content) == ["a/1", "b/1", "c/1"])
        #expect(Self.showsViewAll(context.sut.content) == true)
    }

    @Test("Finished positions light up the badge and mark the wallet as having had positions")
    func finishedPositionsShowTheBadge() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page([])], finished: [.success(true)])
        let context = Self.makeSUT(service: service)

        try await context.log.waitForCount(2)

        #expect(context.sut.content == .noActivePositions(showsViewAll: false))
        #expect(context.sut.hasFinishedPositions)
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

        try await context.log.waitForCount(2)
        #expect(context.sut.content == .failed)

        context.sut.handleViewAction(.retry)

        #expect(context.sut.content == .skeleton(rowCount: 1))
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1"] }
    }

    @Test("An empty list with an unknown history offers a retry instead of hiding the block")
    func unknownHistoryWithoutPositionsFails() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page([])], finished: [.failure(TestError.refused)])
        let context = Self.makeSUT(service: service)

        try await context.log.waitForCount(2)

        #expect(context.sut.content == .failed)
    }

    @Test("A failure after the list has loaded keeps what is on screen")
    func laterFailureKeepsTheList() async throws {
        let service = PositionsBlockServiceStub(
            active: [Self.page(["a"]), .failure(TestError.refused)],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1"] }
        let shown = context.log.contents.count

        await context.refreshCenter.refresh(.full)

        try await context.log.waitForCount(shown + 1)
        #expect(Self.rowIDs(context.sut.content) == ["a/1"])
    }

    // MARK: - Refresh

    @Test("A refresh of the balance or of the account funds leaves the positions alone, a full one reloads them", arguments: QuietScope.allCases)
    func onlyAFullRefreshReloads(_ quietScope: QuietScope) async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"])], finished: [.success(false)])
        let firstLoad = service.holdActiveRequest(1)
        let context = Self.makeSUT(service: service)
        try await firstLoad.entered.next()
        context.presenceStore.markPositionsExisted(for: Self.userWalletId)

        await context.refreshCenter.refresh(quietScope.scope)

        #expect(context.sut.content == .hidden)

        let shown = context.log.contents.count
        await context.refreshCenter.refresh(.full)

        try await context.log.waitForCount(shown + 1)
        #expect(context.log.contents[shown] == .skeleton(rowCount: 1))
        firstLoad.open()
    }

    @Test("A full refresh after a failure keeps the error on screen instead of flashing a skeleton")
    func refreshAfterFailureStaysQuiet() async throws {
        let service = PositionsBlockServiceStub(
            active: [.failure(TestError.refused), .failure(TestError.refused)],
            finished: [.failure(TestError.refused)]
        )
        let context = Self.makeSUT(service: service, hadPositions: true)
        try await context.log.waitUntil { $0 == .failed }
        let shown = context.log.contents.count

        await context.refreshCenter.refresh(.full)

        try await context.log.waitForCount(shown + 1)
        #expect(context.log.contents.dropFirst(shown).allSatisfy { $0 == .failed })
    }

    @Test("Going to background drops the load in flight")
    func backgroundCancelsTheLoadInFlight() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"]), Self.page(["b"])], finished: [.success(false)])
        let reload = service.holdActiveRequest(2)
        let context = Self.makeSUT(service: service)
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1"] }

        await context.refreshCenter.refresh(.full)
        try await reload.entered.next()

        context.appState.enterBackground()

        try await reload.cancelled.next()
        reload.open()
    }

    @Test("Coming back from background reloads the list")
    func foregroundReloads() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a"]), Self.page(["b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1"] }
        try await context.delays.waitUntilParked(Delays.pollInterval)

        context.appState.enterBackground()
        try await context.delays.cancellations.next()
        context.appState.enterForeground()

        try await context.log.waitUntil { Self.rowIDs($0) == ["b/1"] }
    }

    // MARK: - Trades and claims

    @Test("A claimed position leaves the list even when the reload still hands it back")
    func claimedPositionLeaves() async throws {
        let service = PositionsBlockServiceStub(
            active: [Self.page(["a", "b"]), Self.page(["a", "b"]), Self.page(["a", "b", "c"])],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1", "b/1"] }

        context.activityHandler.claimed(Self.position("a"))
        try await context.log.waitUntil { Self.rowIDs($0) == ["b/1"] }

        await context.refreshCenter.refresh(.full)

        try await context.log.waitUntil { Self.rowIDs($0)?.contains("c/1") == true }
        #expect(Self.rowIDs(context.sut.content) == ["b/1", "c/1"])
    }

    @Test("A sold-out position leaves the list even when the reload still hands it back")
    func soldOutPositionLeaves() async throws {
        let service = PositionsBlockServiceStub(
            active: [Self.page(["a", "b"]), Self.page(["a", "b"]), Self.page(["a", "b", "c"])],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1", "b/1"] }

        context.activityHandler.orderPlaced(awaiting: Task { Self.position("a", size: 0) })
        try await context.log.waitUntil { Self.rowIDs($0) == ["b/1"] }

        await context.refreshCenter.refresh(.full)

        try await context.log.waitUntil { Self.rowIDs($0)?.contains("c/1") == true }
        #expect(Self.rowIDs(context.sut.content) == ["b/1", "c/1"])
    }

    @Test("A partial sale updates the row in place")
    func partialSaleUpdatesTheRow() async throws {
        let service = PositionsBlockServiceStub(active: [Self.page(["a", "b"])], finished: [.success(false)])
        let context = Self.makeSUT(service: service)
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1", "b/1"] }

        context.activityHandler.orderPlaced(awaiting: Task { Self.position("a", size: 2, title: "Updated") })

        try await context.log.waitUntil { Self.rowQuestions($0)?.first == "Updated" }
        #expect(Self.rowIDs(context.sut.content) == ["a/1", "b/1"])
    }

    @Test("A claim or a trade reported back through the router takes the position off the block", arguments: RouterCallback.allCases)
    func routerCallbackLeavesTheList(_ callback: RouterCallback) async throws {
        let service = PositionsBlockServiceStub(
            active: [.success(PolymarketPositionsPage(
                positions: [Self.position("a"), Self.position("b"), Self.position("r", isRedeemable: true)],
                receivedCount: 3,
                nextCursor: nil
            ))],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1", "b/1", "r/1"] }

        switch callback {
        case .claimOnTheClaimScreen:
            context.sut.handleViewAction(.openPositionDetails(id: "r/1"))
            let onClaimed = try #require(context.routable.lastOnClaimed)
            onClaimed(Self.position("r", isRedeemable: true))
            try await context.log.waitUntil { Self.rowIDs($0) == ["a/1", "b/1"] }
        case .claimFromMyPositions:
            context.sut.handleViewAction(.openMyPositions(.active))
            let onClaimed = try #require(context.routable.lastOnClaimed)
            onClaimed(Self.position("a"))
            try await context.log.waitUntil { Self.rowIDs($0) == ["b/1", "r/1"] }
        case .tradeFromMyPositions:
            context.sut.handleViewAction(.openMyPositions(.active))
            let onOrderPlaced = try #require(context.routable.lastOnOrderPlaced)
            onOrderPlaced(Task { Self.position("a", size: 0) })
            try await context.log.waitUntil { Self.rowIDs($0) == ["b/1", "r/1"] }
        case .tradeOnThePositionDetails:
            context.sut.handleViewAction(.openPositionDetails(id: "a/1"))
            let onOrderPlaced = try #require(context.routable.lastOnOrderPlaced)
            onOrderPlaced(Task { Self.position("a", size: 0) })
            try await context.log.waitUntil { Self.rowIDs($0) == ["b/1", "r/1"] }
        }
    }

    // MARK: - Navigation

    @Test("A running position opens its details, a redeemable one opens the claim")
    func tappedRowLeadsWhereItShould() async throws {
        let service = PositionsBlockServiceStub(
            active: [.success(PolymarketPositionsPage(
                positions: [Self.position("a"), Self.position("b", isRedeemable: true)],
                receivedCount: 2,
                nextCursor: nil
            ))],
            finished: [.success(false)]
        )
        let context = Self.makeSUT(service: service)
        try await context.log.waitUntil { Self.rowIDs($0) == ["a/1", "b/1"] }

        context.sut.handleViewAction(.openPositionDetails(id: "a/1"))
        context.sut.handleViewAction(.openPositionDetails(id: "b/1"))

        #expect(context.routable.detailedIDs == ["a/1"])
        #expect(context.routable.redeemedIDs == ["b/1"])
    }
}

// MARK: - Arguments

extension PolymarketPositionsBlockViewModelTests {
    enum QuietScope: CaseIterable, Sendable {
        case balance
        case accountFunds

        var scope: PolymarketMainRefreshCenter.Scope {
            switch self {
            case .balance: .balance
            case .accountFunds: .accountFunds
            }
        }
    }

    enum RouterCallback: CaseIterable, Sendable {
        case claimOnTheClaimScreen
        case claimFromMyPositions
        case tradeFromMyPositions
        case tradeOnThePositionDetails
    }
}

// MARK: - Helpers

private extension PolymarketPositionsBlockViewModelTests {
    @MainActor
    struct Context {
        let sut: PolymarketPositionsBlockViewModel
        let presenceStore: PolymarketAccountPresenceStoreStub
        let refreshCenter: PolymarketMainRefreshCenter
        let activityHandler: PolymarketMainActivityHandler
        let routable: PositionsBlockRoutableSpy
        let appState: AppStateObserverStub
        let delays: PolymarketSteppedDelayProvider
        let log: ContentLog
    }

    static let userWalletId = UserWalletId(value: Data([0x01, 0x02, 0x03]))

    static func makeSUT(
        service: PositionsBlockServiceStub,
        hadPositions: Bool = false,
        presenceStore: PolymarketAccountPresenceStoreStub? = nil
    ) -> Context {
        let presenceStore = presenceStore ?? PolymarketAccountPresenceStoreStub(positions: hadPositions)
        let refreshCenter = PolymarketMainRefreshCenter()
        let activityHandler = PolymarketMainActivityHandler(
            fundsArrivalTracker: PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher()),
            refreshCenter: refreshCenter
        )
        let routable = PositionsBlockRoutableSpy()
        let appState = AppStateObserverStub()
        let delays = PolymarketSteppedDelayProvider()

        let sut = PolymarketPositionsBlockViewModel(
            positionsService: service,
            presenceStore: presenceStore,
            userWalletId: userWalletId,
            refreshCenter: refreshCenter,
            activityHandler: activityHandler,
            routable: routable,
            appStateObserver: appState,
            delayProvider: delays
        )

        return Context(
            sut: sut,
            presenceStore: presenceStore,
            refreshCenter: refreshCenter,
            activityHandler: activityHandler,
            routable: routable,
            appState: appState,
            delays: delays,
            log: ContentLog(sut)
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
            nextCursor: nil
        ))
    }

    static func position(
        _ conditionId: String,
        size: Decimal = 1,
        isRedeemable: Bool = false,
        title: String = "Question"
    ) -> PolymarketPosition {
        PolymarketPosition(
            conditionId: conditionId,
            assetId: "1",
            marketId: "3",
            version: .v1,
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
            settlement: nil
        )
    }
}

private enum Delays {
    static let pollInterval: TimeInterval = 20
}

// MARK: - Doubles

private enum TestError: Error {
    case refused
}

@MainActor
private final class ContentLog {
    private(set) var contents: [PolymarketPositionsBlockViewModel.Content] = []

    private let changes = PolymarketTestSignal<Void>()
    private var subscription: AnyCancellable?

    init(_ sut: PolymarketPositionsBlockViewModel) {
        subscription = sut.$content.sink { [weak self] content in
            self?.contents.append(content)
            self?.changes.send()
        }
    }

    func waitForCount(_ count: Int) async throws {
        try await changes.waitForCount(count)
    }

    func waitUntil(_ isMatching: (PolymarketPositionsBlockViewModel.Content) -> Bool) async throws {
        while !(contents.last.map(isMatching) ?? false) {
            try await changes.next()
        }
    }
}

@MainActor
private final class PositionsBlockServiceStub: PolymarketPositionsService {
    private let active: [Result<PolymarketPositionsPage, Error>]
    private let finished: [Result<Bool, Error>]
    private var activeRequests = 0
    private var finishedRequests = 0
    private var heldActiveRequests: [Int: PolymarketTestGate] = [:]

    init(active: [Result<PolymarketPositionsPage, Error>], finished: [Result<Bool, Error>]) {
        self.active = active
        self.finished = finished
    }

    func holdActiveRequest(_ number: Int) -> PolymarketTestGate {
        let gate = PolymarketTestGate()
        heldActiveRequests[number] = gate
        return gate
    }

    func activePositions(limit: Int) async throws -> PolymarketPositionsPage {
        activeRequests += 1
        let result = active[safe: activeRequests - 1] ?? active.last

        if let gate = heldActiveRequests[activeRequests] {
            await gate.pass()
        }

        return try result?.get() ?? PolymarketPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
    }

    func closedPositions(limit: Int, cursor: String?) async throws -> PolymarketClosedPositionsPage {
        let result = finished[safe: finishedRequests] ?? finished.last
        finishedRequests += 1
        let exists = try result?.get() ?? false

        return PolymarketClosedPositionsPage(
            positions: exists ? [Self.closedPosition] : [],
            receivedCount: exists ? 1 : 0,
            nextCursor: nil
        )
    }

    func openPositions(limit: Int, cursor: String?) async throws -> PolymarketPositionsPage {
        PolymarketPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
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
    private(set) var lastOnOrderPlaced: (@MainActor (PolymarketOrderIndexing) -> Void)?
    private(set) var lastOnClaimed: ((PolymarketPosition?) -> Void)?

    func openMyPositions(
        tab: PolymarketPositionsTab,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onClaimed: @escaping (PolymarketPosition?) -> Void
    ) {
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
