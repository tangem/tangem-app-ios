//
//  PolymarketEventsBlockViewModelTests.swift
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
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket events block", .timeLimit(.minutes(1)))
@MainActor
struct PolymarketEventsBlockViewModelTests {
    private typealias Games = PolymarketLiveGamesFixtures

    @Test("Coming back to a visited category shows it again without asking the backend")
    func visitedCategoryComesFromCache() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1), Self.category(2)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"]),
            .init(category: 2, cursor: nil): Self.page(["b"]),
        ]
        let sut = Self.makeSUT(provider: provider)

        await Self.cards(of: sut, become: ["a"])

        sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        await Self.cards(of: sut, become: ["b"])

        sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 1, title: "")

        #expect(Self.cardIDs(sut) == ["a"])
        #expect(provider.eventsRequests.count == 2)
    }

    @Test("A page made only of events already shown asks for the next page")
    func duplicatePageLoadsTheNextOne() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["a"], cursor: "c2"),
            .init(category: 1, cursor: "c2"): Self.page(["b"]),
        ]
        let sut = Self.makeSUT(provider: provider)
        await Self.loadingState(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(Self.cardIDs(sut) == ["a", "b"])
        #expect(provider.eventsRequests.map(\.cursor) == [nil, "c1", "c2"])
    }

    @Test("A backend that keeps returning only events already shown stops being asked after a few pages")
    func endlessDuplicatePagesStop() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["a"], cursor: "c1"),
        ]
        let sut = Self.makeSUT(provider: provider)
        await Self.loadingState(of: sut, becomes: .loaded)

        sut.handleViewAction(.loadNextPage)

        await Self.loadingState(of: sut, becomes: .loaded)
        #expect(provider.eventsRequests.count == 5)
        #expect(Self.cardIDs(sut) == ["a"])
    }

    @Test("Retrying after the categories failed to load brings the feed back")
    func retryAfterFailedCategoriesLoadsTheFeed() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.queuedCategoryResults = [.failure(EventsTestError.unavailable)]
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [.init(category: 1, cursor: nil): Self.page(["a"])]
        let sut = Self.makeSUT(provider: provider)

        await Self.loadingState(of: sut, becomes: .error)

        sut.handleViewAction(.retry)

        await Self.loadingState(of: sut, becomes: .allDataLoaded)
        #expect(Self.cardIDs(sut) == ["a"])
    }

    @Test("A tab picked while the retried feed is still loading shows only its own events")
    func tabPickedDuringRetryKeepsItsOwnEvents() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.queuedCategoryResults = [.failure(EventsTestError.unavailable)]
        provider.categoryList = [Self.category(1), Self.category(2)]
        provider.heldEventCategories = [1]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"]),
            .init(category: 2, cursor: nil): Self.page(["b"]),
        ]
        let sut = Self.makeSUT(provider: provider)
        await Self.loadingState(of: sut, becomes: .error)

        sut.handleViewAction(.retry)
        try await provider.heldEvents.entered.next()

        sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        await Self.loadingState(of: sut, becomes: .allDataLoaded)

        provider.heldEvents.open()
        sut.handleViewAction(.retry)
        try await provider.eventsRequested.waitForCount(3)
        await Self.loadingState(of: sut, becomes: .allDataLoaded)

        #expect(Self.cardIDs(sut) == ["b"])
    }

    @Test("Choosing an outcome in a restricted region opens the region warning instead of the order")
    func restrictedRegionOpensWarning() async throws {
        let outcome = PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.42)
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [.init(category: 1, cursor: nil): Self.page(["a"], outcomes: [outcome])]
        let routable = PolymarketEventOpeningRoutableSpy()
        let sut = Self.makeSUT(provider: provider, routable: routable, isRegionRestricted: true)

        await Self.cards(of: sut, become: ["a"])

        let selected = try #require(sut.eventCards.first?.regularModel?.rows.first?.outcomes.first)
        selected.onSelect()

        #expect(routable.openedOutcomes.isEmpty)
        #expect(routable.regionWarningOpenings == 1)
        withExtendedLifetime(sut) {}
    }

    // MARK: - Polling

    @Test("A visible page older than the stale age is asked for again with its own cursor")
    func staleVisiblePageIsRefreshed() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.provider.eventsRequests.count == 2)
        #expect(context.provider.eventsRequests.last?.cursor == nil)
        #expect(context.provider.eventsRequests.last?.category == 1)
    }

    @Test("A fresh page and a page off screen are not asked for")
    func freshOrHiddenPagesAreNotRefreshed() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await context.runVisibilityTick()

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: false))
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "elsewhere", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.provider.eventsRequests.count == 1)

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.provider.eventsRequests.count == 2)
    }

    @Test("A failed later page keeps the feed as it is")
    func failedLaterPageKeepsTheFeed() async throws {
        let context = try await Self.makePollingContext(pages: [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["b"]),
        ])

        context.sut.handleViewAction(.loadNextPage)
        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)

        context.provider.eventErrors = [.init(category: 1, cursor: "c1"): Self.badGateway]
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "b", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.provider.eventsRequests.map(\.cursor) == [nil, "c1", "c1"])
        #expect(Self.cardIDs(context.sut) == ["a", "b"])
    }

    @Test("A next page that failed is asked again with the same cursor")
    func failedNextPageKeepsItsCursor() async throws {
        let context = try await Self.makePollingContext(pages: [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["b"]),
        ])

        context.provider.eventErrors = [.init(category: 1, cursor: "c1"): Self.badGateway]
        context.sut.handleViewAction(.loadNextPage)
        await Self.loadingState(of: context.sut, becomes: .paginationError)

        context.provider.eventErrors = [:]
        context.sut.handleViewAction(.retryNextPage)

        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)
        #expect(Self.cardIDs(context.sut) == ["a", "b"])
        #expect(context.provider.eventsRequests.map(\.cursor) == [nil, "c1", "c1", "c1"])
    }

    @Test("A failed first page keeps the feed as it is")
    func failedFirstPageIsNotAStaleCursor() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.provider.eventErrors = [.init(category: 1, cursor: nil): Self.badGateway]
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await context.runVisibilityTick()

        #expect(context.provider.eventsRequests.count == 2)
        #expect(Self.cardIDs(context.sut) == ["a"])
    }

    @Test("Three failed refreshes in a row report outdated data once, and again only after the cooldown")
    func repeatedFailuresReportOutdatedData() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.provider.eventErrors = [.init(category: 1, cursor: nil): Self.unavailable]
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))

        try await Self.failRefresh(context)
        try await Self.failRefresh(context)
        #expect(context.outdatedDataLog.reports == 0)

        try await Self.failRefresh(context)
        #expect(context.outdatedDataLog.reports == 1)

        try await Self.failRefresh(context)
        try await Self.failRefresh(context)
        #expect(context.outdatedDataLog.reports == 1)

        context.clock.advance(by: 300)
        try await Self.failRefresh(context)
        #expect(context.outdatedDataLog.reports == 2)
        #expect(context.provider.eventsRequests.count == 7)
    }

    @Test("In background a page coming on screen is not asked for, coming back asks for it at once")
    func backgroundPausesRefreshes() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.appState.enterBackground()
        try await context.delays.cancellations.next()

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))

        context.appState.enterForeground()
        try await context.provider.eventsRequested.waitForCount(2)

        #expect(!context.delays.requests.recorded.contains(Delays.visibilitySettleDelay))
        #expect(context.provider.eventsRequests.count == 2)
    }

    @Test("While search is open a page coming on screen is not asked for, closing search asks for it at once")
    func suspendedPollingSkipsRefreshes() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.sut.setPollingSuspended(true)

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))

        context.sut.setPollingSuspended(false)
        try await context.provider.eventsRequested.waitForCount(2)

        #expect(!context.delays.requests.recorded.contains(Delays.visibilitySettleDelay))
        #expect(context.provider.eventsRequests.count == 2)
    }

    @Test("A poll answer arriving after the tab changed is not merged into the new tab")
    func pollAnswerAfterTabChangeIsDropped() async throws {
        let context = try await Self.makePollingContext(
            categories: [1, 2],
            pages: [
                .init(category: 1, cursor: nil): Self.page(["a"]),
                .init(category: 2, cursor: nil): Self.page(["b"]),
            ]
        )

        context.provider.heldEventCategories = [1]
        context.provider.eventPages[.init(category: 1, cursor: nil)] = PolymarketEventsPage(
            events: [Self.event(id: "b", title: "stale"), Self.event(id: "a")],
            cursor: nil
        )
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        context.appState.enterForeground()
        try await context.provider.heldEvents.entered.next()

        context.sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "b", isVisible: true))

        context.provider.heldEvents.open()
        try await context.runVisibilityTick()

        #expect(context.sut.eventCards.map(\.regularModel?.title) == ["b"])
    }

    @Test("An outcome chosen on a card drawn before a poll opens the order with the market from that poll")
    func outcomeChosenAfterPollOpensTheFreshMarket() async throws {
        let routable = PolymarketEventOpeningRoutableSpy()
        let context = try await Self.makePollingContext(
            pages: [.init(category: 1, cursor: nil): Self.page(["a"], outcomes: [Self.outcome(probability: "0.42")])],
            routable: routable
        )
        let cardBeforePoll = try #require(context.sut.eventCards.first?.regularModel?.rows.first?.outcomes.first)

        context.provider.eventPages[.init(category: 1, cursor: nil)] = Self.page(["a"], outcomes: [Self.outcome(probability: "0.55")])
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await context.runVisibilityTick()
        #expect(Self.priceTexts(context.sut).first == Self.cents("0.55"))

        cardBeforePoll.onSelect()

        #expect(routable.openedOutcomes.map(\.outcome.probability) == [Decimal(string: "0.55")])
        #expect(routable.openedOutcomes.map(\.market.id) == ["a-market"])
    }

    // MARK: - Live quotes

    @Test("A live quote puts its best ask on the outcome button, an empty ask shows a dash")
    func liveQuoteShowsTheBestAsk() async throws {
        let context = try await Self.makeLiveContext()

        try await context.deliver(PolymarketLiveQuotesFixtures.quote("a-m0-yes", bid: "0.36", ask: "0.37"))
        try await context.deliver(PolymarketLiveQuotesFixtures.quote("a-m0-no", bid: "0.62"))

        await Self.priceTexts(of: context.sut, become: [Self.cents("0.37"), BalanceFormatter.defaultEmptyBalanceString])
    }

    @Test("A batch that changes no price on screen does not republish the cards")
    func unchangedPricesAreNotRepublished() async throws {
        let context = try await Self.makeLiveContext()
        var publishes = 0
        let subscription = context.sut.$eventCards.dropFirst().sink { _ in publishes += 1 }

        try await context.deliver(PolymarketLiveQuotesFixtures.quote("a-m0-yes", bid: "0.30", ask: "0.37"))
        try await context.deliver(PolymarketLiveQuotesFixtures.quote("a-m0-yes", bid: "0.31", ask: "0.37"))
        try await context.deliver(PolymarketLiveQuotesFixtures.quote("a-m0-yes", bid: "0.31", ask: "0.38"))
        await Self.firstPriceText(of: context.sut, becomes: Self.cents("0.38"))

        #expect(publishes == 2)
        withExtendedLifetime(subscription) {}
    }

    @Test("A lost connection brings the prices from the backend back")
    func lostConnectionFallsBackToBackendPrices() async throws {
        let context = try await Self.makeLiveContext()

        try await context.deliver(PolymarketLiveQuotesFixtures.quote("a-m0-yes", ask: "0.37"))
        await Self.firstPriceText(of: context.sut, becomes: Self.cents("0.37"))

        context.liveQuotes.statuses.push(.waitingToReconnect)

        await Self.priceTexts(of: context.sut, become: [Self.cents("0.42"), Self.cents("0.58")])
    }

    // MARK: - Live games

    @Test("Each button of a soccer card opens the order for its own market and outcome")
    func liveCardButtonsBuyTheirOwnOutcome() async throws {
        let routable = PolymarketEventOpeningRoutableSpy()
        let context = try await Self.makeGameContext(events: [Games.soccer()], routable: routable)
        let card = try #require(context.sut.eventCards.first?.liveGameModel)

        card.outcomes.forEach { $0.onSelect() }

        #expect(routable.openedOutcomes.map(\.market.id) == ["1201001-ars", "1201001-draw", "1201001-che"])
        #expect(routable.openedOutcomes.map(\.outcome.assetId) == ["1201001-ars-yes", "1201001-draw-yes", "1201001-che-yes"])
    }

    @Test("A live quote puts its price on the matching button of a live match card")
    func liveQuoteReachesTheLiveCard() async throws {
        let context = try await Self.makeGameContext(events: [Games.soccer()])
        context.sut.handleViewAction(.onEventVisibilityChange(id: "1201001", isVisible: true))
        let stream = try await context.liveQuotes.requests.next()

        stream.push(PolymarketLiveQuotesFixtures.quote("1201001-draw-yes", bid: "0.26", ask: "0.27"))

        let expected = PolymarketPriceFormatter.wholeCentsText(Decimal(string: "0.27"))
        _ = await context.sut.$eventCards.firstValue { $0.first?.liveGameModel?.outcomes[safe: 1]?.priceText == expected }
    }

    @Test("When the socket and the feed put a match on the same stage, the card shows the socket score, because the feed score lags behind")
    func socketScoreWinsOnTheSameStage() async throws {
        let context = try await Self.makeGameContext(events: [Games.basketball()])

        context.push(Games.liveGame(Games.basketballGameId, score: "100-101"))

        await Self.awayScore(of: context.sut, becomes: "100")
    }

    @Test("A lost socket brings the score from REST back")
    func lostSocketFallsBackToRest() async throws {
        let context = try await Self.makeGameContext(events: [Games.basketball()])

        context.push(Games.liveGame(Games.basketballGameId, score: "100-101"))
        await Self.awayScore(of: context.sut, becomes: "100")

        context.liveGames.statuses.push(.waitingToReconnect)

        await Self.awayScore(of: context.sut, becomes: "98")
    }

    @Test("After a real reconnection only the pages on screen are asked again, each with its own cursor")
    func reconnectionRefetchesVisiblePages() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.eventPages = [
            .init(category: 1, cursor: nil): PolymarketEventsPage(events: [Games.soccer()], cursor: "c1"),
            .init(category: 1, cursor: "c1"): PolymarketEventsPage(events: [Games.basketball()], cursor: nil),
        ]
        let context = try await Self.makeGameContext(provider: provider)
        context.sut.handleViewAction(.loadNextPage)
        await Self.loadingState(of: context.sut, becomes: .allDataLoaded)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "1197295", isVisible: true))
        let requestsBefore = provider.eventsRequests.count

        context.reconnect()
        try await provider.eventsRequested.waitForCount(requestsBefore + 1)

        provider.heldEventCategories = [1]
        context.reconnect()
        try await provider.heldEvents.entered.next()

        #expect(provider.eventsRequests.dropFirst(requestsBefore).map(\.cursor) == ["c1", "c1"])
    }

    @Test("A second reconnection while the first refetch still waits for the backend asks for the page again")
    func secondReconnectionDuringARefetchStillRefetches() async throws {
        let provider = PolymarketAPIProviderStub()
        let context = try await Self.makeGameContext(events: [Games.basketball()], provider: provider)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "1197295", isVisible: true))
        let requestsBefore = provider.eventsRequests.count
        provider.heldEventCategories = [1]

        context.reconnect()
        try await provider.heldEvents.entered.next()
        context.reconnect()
        try await provider.heldEvents.cancelled.next()

        provider.heldEvents.open()

        try await provider.eventsRequested.waitForCount(requestsBefore + 2)
    }

    @Test("A match the socket reports started gets its quotes followed before REST catches up")
    func socketStartFollowsQuotes() async throws {
        let match = Games.basketball(isLive: false, score: nil, period: nil)
        let context = try await Self.makeGameContext(events: [match])
        context.sut.handleViewAction(.onEventVisibilityChange(id: match.id, isVisible: true))
        try await context.delays.waitUntilParked(Delays.visibilitySettleDelay)
        #expect(context.liveQuotes.requests.recorded.isEmpty)

        context.push(Games.liveGame(Games.basketballGameId, score: "2-0", period: "Q1"))

        let stream = try await context.liveQuotes.requests.next()
        #expect(stream.assetIds.contains("1197295-phi"))
    }

    @Test("Without phase two a live match stays on the regular card with the bullet")
    func withoutPhaseTwoMatchesKeepTheRegularCard() async throws {
        let context = try await Self.makeGameContext(events: [Games.basketball(), Self.event(id: "rain")], usesPhaseTwoCards: false)

        #expect(context.sut.eventCards.map(\.regularModel?.outcomeLabelStyle) == [.bulletSeparated, .bulletSeparated])
    }

    @Test("With phase two a live match gets the live card and the other cards the compact buttons")
    func withPhaseTwoMatchesGetTheLiveCard() async throws {
        let context = try await Self.makeGameContext(events: [Games.basketball(), Self.event(id: "rain")])

        #expect(context.sut.eventCards.first?.liveGameModel != nil)
        #expect(context.sut.eventCards.last?.regularModel?.outcomeLabelStyle == .compact)
    }

    @Test("A frame matching what the card already shows does not republish, and a frame of one match leaves the other cards as they were")
    func framesRepublishOnlyWhatChanged() async throws {
        let context = try await Self.makeGameContext(events: [Games.basketball(), Games.soccer()])
        let soccerCard = context.sut.eventCards.last
        var publishes = 0
        let subscription = context.sut.$eventCards.dropFirst().sink { _ in publishes += 1 }

        context.push(Games.liveGame(Games.basketballGameId, score: "98-101"))
        context.push(Games.liveGame(Games.basketballGameId, score: "100-101"))
        await Self.awayScore(of: context.sut, becomes: "100")

        #expect(publishes == 1)
        #expect(context.sut.eventCards.last == soccerCard)
        withExtendedLifetime(subscription) {}
    }

    @Test("Coming back to a category from the cache follows its matches again")
    func restoredCategoryFollowsItsMatches() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1), Self.category(2)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): PolymarketEventsPage(events: [Games.basketball()], cursor: nil),
            .init(category: 2, cursor: nil): Self.page(["b"]),
        ]
        let context = try await Self.makeGameContext(provider: provider)

        context.sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        await Self.cards(of: context.sut, become: ["b"])
        context.sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 1, title: "")
        #expect(Self.cardIDs(context.sut) == ["1197295"])
        try await context.liveGames.requests.next()

        context.push(Games.liveGame(Games.basketballGameId, score: "100-101"))

        await Self.awayScore(of: context.sut, becomes: "100")
    }
}

// MARK: - Helpers

private extension PolymarketEventsBlockViewModelTests {
    static func makeSUT(
        provider: PolymarketAPIProviderStub,
        routable: PolymarketEventOpeningRoutableSpy = PolymarketEventOpeningRoutableSpy.ignored,
        isRegionRestricted: Bool = false,
        appState: AppStateObserverStub = AppStateObserverStub(),
        clock: PollingClock = PollingClock(),
        delays: PolymarketSteppedDelayProvider = PolymarketSteppedDelayProvider(passing: { $0 == Delays.silentRetryDelay }),
        outdatedDataLog: OutdatedDataLog = OutdatedDataLog(),
        liveQuotes: PolymarketLiveQuotesSourceSpy = PolymarketLiveQuotesSourceSpy(),
        quoteBatches: any PollDelayProvider = InstantPollDelayProvider(),
        liveGames: PolymarketLiveGamesSourceSpy = PolymarketLiveGamesSourceSpy(),
        usesPhaseTwoCards: Bool = false
    ) -> PolymarketEventsBlockViewModel {
        let refreshCenter = PolymarketMainRefreshCenter()

        return PolymarketEventsBlockViewModel(
            apiProvider: provider,
            refreshCenter: refreshCenter,
            activityHandler: PolymarketMainActivityHandler(
                fundsArrivalTracker: PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher()),
                refreshCenter: refreshCenter
            ),
            liveQuotesTracker: liveQuotes.makeTracker(delayProvider: quoteBatches),
            liveGamesTracker: liveGames.makeTracker(),
            usesPhaseTwoCards: usesPhaseTwoCards,
            isRegionRestricted: { isRegionRestricted },
            routable: routable,
            appStateObserver: appState,
            now: { clock.now },
            delayProvider: delays,
            reportOutdatedData: { outdatedDataLog.reports += 1 }
        )
    }

    static func cards(of sut: PolymarketEventsBlockViewModel, become ids: [String]) async {
        _ = await sut.$eventCards.firstValue { $0.map(\.id) == ids }
    }

    static func loadingState(of sut: PolymarketEventsBlockViewModel, becomes state: PolymarketEventsBlockViewModel.LoadingState) async {
        _ = await sut.$loadingState.firstValue { $0 == state }
    }

    static func priceTexts(of sut: PolymarketEventsBlockViewModel, become texts: [String?]) async {
        _ = await sut.$eventCards.firstValue { $0.first?.regularModel?.rows.first?.outcomes.map(\.priceText) == texts }
    }

    static func firstPriceText(of sut: PolymarketEventsBlockViewModel, becomes text: String) async {
        _ = await sut.$eventCards.firstValue { $0.first?.regularModel?.rows.first?.outcomes.first?.priceText == text }
    }

    static func awayScore(of sut: PolymarketEventsBlockViewModel, becomes away: String) async {
        _ = await sut.$eventCards.firstValue { $0.first { $0.id == "1197295" }?.liveGameModel?.score?.away == away }
    }

    @MainActor
    struct PollingContext {
        let sut: PolymarketEventsBlockViewModel
        let provider: PolymarketAPIProviderStub
        let clock: PollingClock
        let delays: PolymarketSteppedDelayProvider
        let outdatedDataLog: OutdatedDataLog
        let appState: AppStateObserverStub

        func runVisibilityTick() async throws {
            try await delays.waitUntilParked(Delays.visibilitySettleDelay)
            delays.resume(Delays.visibilitySettleDelay)

            sut.handleViewAction(.onEventVisibilityChange(id: UUID().uuidString, isVisible: true))
            try await delays.waitUntilParked(Delays.visibilitySettleDelay)
        }
    }

    static let badGateway = PolymarketAPIError.http(statusCode: 502, problemDetail: nil)
    static let unavailable = PolymarketAPIError.http(statusCode: 503, problemDetail: nil)

    static func makePollingContext(
        categories: [Int] = [1],
        pages: [PolymarketAPIProviderStub.EventsPageKey: PolymarketEventsPage],
        routable: PolymarketEventOpeningRoutableSpy = PolymarketEventOpeningRoutableSpy.ignored
    ) async throws -> PollingContext {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = categories.map(category)
        provider.eventPages = pages
        let clock = PollingClock()
        let delays = PolymarketSteppedDelayProvider(passing: { $0 == Delays.silentRetryDelay })
        let outdatedDataLog = OutdatedDataLog()
        let appState = AppStateObserverStub()
        let sut = makeSUT(
            provider: provider,
            routable: routable,
            appState: appState,
            clock: clock,
            delays: delays,
            outdatedDataLog: outdatedDataLog
        )

        _ = await sut.$loadingState.firstValue { $0 == .loaded || $0 == .allDataLoaded }
        try await delays.waitUntilParked(Delays.pollInterval)

        return PollingContext(
            sut: sut,
            provider: provider,
            clock: clock,
            delays: delays,
            outdatedDataLog: outdatedDataLog,
            appState: appState
        )
    }

    static func failRefresh(_ context: PollingContext) async throws {
        context.clock.advance(by: 21)
        try await context.runVisibilityTick()
    }

    @MainActor
    struct LiveContext {
        let sut: PolymarketEventsBlockViewModel
        let liveQuotes: PolymarketLiveQuotesSourceSpy
        let quoteBatches: PolymarketSteppedDelayProvider
        let stream: PolymarketLiveStreamSpy<PolymarketOutcomeQuote>

        func deliver(_ quote: PolymarketOutcomeQuote) async throws {
            stream.push(quote)
            try await quoteBatches.waitUntilParked(Delays.quoteBatchInterval)
            quoteBatches.resume()
        }
    }

    static func makeLiveContext() async throws -> LiveContext {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [category(1)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): PolymarketEventsPage(events: [PolymarketLiveQuotesFixtures.event(id: "a")], cursor: nil),
        ]
        let liveQuotes = PolymarketLiveQuotesSourceSpy()
        let quoteBatches = PolymarketSteppedDelayProvider()
        let sut = makeSUT(provider: provider, liveQuotes: liveQuotes, quoteBatches: quoteBatches)

        await cards(of: sut, become: ["a"])

        liveQuotes.statuses.push(.connected)
        try await liveQuotes.statuses.waitForPulls(2)

        sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        let stream = try await liveQuotes.requests.next()

        return LiveContext(sut: sut, liveQuotes: liveQuotes, quoteBatches: quoteBatches, stream: stream)
    }

    @MainActor
    struct GameContext {
        let sut: PolymarketEventsBlockViewModel
        let liveGames: PolymarketLiveGamesSourceSpy
        let liveQuotes: PolymarketLiveQuotesSourceSpy
        let delays: PolymarketSteppedDelayProvider

        func push(_ game: PolymarketLiveGame) {
            guard let stream = liveGames.streams.last else {
                Issue.record("No games are followed")
                return
            }

            stream.push(game)
        }

        func reconnect() {
            liveGames.statuses.push(.waitingToReconnect)
            liveGames.statuses.push(.connected)
        }
    }

    static func makeGameContext(
        events: [PolymarketEvent] = [],
        provider: PolymarketAPIProviderStub = PolymarketAPIProviderStub(),
        routable: PolymarketEventOpeningRoutableSpy = PolymarketEventOpeningRoutableSpy.ignored,
        usesPhaseTwoCards: Bool = true
    ) async throws -> GameContext {
        if provider.categoryList.isEmpty {
            provider.categoryList = [category(1)]
        }

        if !events.isEmpty {
            provider.eventPages[.init(category: 1, cursor: nil)] = PolymarketEventsPage(events: events, cursor: nil)
        }

        let liveGames = PolymarketLiveGamesSourceSpy()
        let liveQuotes = PolymarketLiveQuotesSourceSpy()
        let delays = PolymarketSteppedDelayProvider(passing: { $0 == Delays.silentRetryDelay })
        let sut = makeSUT(
            provider: provider,
            routable: routable,
            delays: delays,
            liveQuotes: liveQuotes,
            liveGames: liveGames,
            usesPhaseTwoCards: usesPhaseTwoCards
        )

        _ = await sut.$loadingState.firstValue { $0 == .loaded || $0 == .allDataLoaded }
        try await liveGames.requests.next()
        liveGames.statuses.push(.connected)
        try await liveGames.statuses.waitForPulls(2)

        return GameContext(sut: sut, liveGames: liveGames, liveQuotes: liveQuotes, delays: delays)
    }

    static func priceTexts(_ sut: PolymarketEventsBlockViewModel) -> [String?] {
        sut.eventCards.first?.regularModel?.rows.first?.outcomes.map(\.priceText) ?? []
    }

    static func cents(_ probability: String) -> String {
        PolymarketPriceFormatter.centsText(Decimal(string: probability))
    }

    static func outcome(probability: String) -> PolymarketOutcome {
        PolymarketOutcome(assetId: "yes", title: "Yes", probability: Decimal(string: probability))
    }

    static func cardIDs(_ sut: PolymarketEventsBlockViewModel) -> [String] {
        sut.eventCards.map(\.id)
    }

    static func market(id: String, outcomes: [PolymarketOutcome]) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
            title: id,
            groupItemTitle: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: 0,
            outcomes: outcomes
        )
    }

    static func category(_ id: Int) -> PolymarketCategory {
        PolymarketCategory(id: id, label: "\(id)", icon: nil)
    }

    static func page(_ ids: [String], cursor: String? = nil, outcomes: [PolymarketOutcome] = []) -> PolymarketEventsPage {
        PolymarketEventsPage(
            events: ids.map { event(id: $0, outcomes: outcomes) },
            cursor: cursor
        )
    }

    static func event(id: String, title: String? = nil, outcomes: [PolymarketOutcome] = []) -> PolymarketEvent {
        let markets = outcomes.isEmpty ? [] : [market(id: "\(id)-market", outcomes: outcomes)]

        return PolymarketEvent(
            id: id,
            slug: id,
            title: title ?? id,
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isLive: false,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: markets.count,
            isNegRisk: false,
            displayMode: .plainMarkets,
            markets: markets
        )
    }
}

private enum Delays {
    static let visibilitySettleDelay: TimeInterval = 0.5
    static let silentRetryDelay: TimeInterval = 2
    static let quoteBatchInterval: TimeInterval = 0.3
    static let pollInterval: TimeInterval = 20
}

// MARK: - Doubles

private final class PollingClock {
    private(set) var now = Date(timeIntervalSince1970: 1_800_000_000)

    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }
}

private final class OutdatedDataLog {
    var reports = 0
}

private enum EventsTestError: Error {
    case unavailable
}
