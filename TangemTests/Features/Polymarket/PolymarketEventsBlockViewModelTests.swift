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

@Suite("Polymarket events block")
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

        try await settle { Self.cardIDs(sut) == ["a"] }

        sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        try await settle { Self.cardIDs(sut) == ["b"] }

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

        try await settle { Self.cardIDs(sut) == ["a"] }

        sut.handleViewAction(.loadNextPage)

        try await settle { Self.cardIDs(sut) == ["a", "b"] }

        #expect(provider.eventsRequests.map(\.cursor) == [nil, "c1", "c2"])
        #expect(sut.loadingState == .allDataLoaded)
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

        try await settle { Self.cardIDs(sut) == ["a"] }

        sut.handleViewAction(.loadNextPage)

        try await settle { provider.eventsRequests.count == 5 }
        try await drain()

        #expect(provider.eventsRequests.count == 5)
        #expect(sut.loadingState == .loaded)
        #expect(Self.cardIDs(sut) == ["a"])
    }

    @Test("Retrying after the categories failed to load brings the feed back")
    func retryAfterFailedCategoriesLoadsTheFeed() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.queuedCategoryResults = [.failure(EventsTestError.unavailable)]
        provider.categoryList = [Self.category(1)]
        provider.eventPages = [.init(category: 1, cursor: nil): Self.page(["a"])]
        let sut = Self.makeSUT(provider: provider)

        try await settle { sut.loadingState == .error }

        sut.handleViewAction(.retry)

        try await settle { Self.cardIDs(sut) == ["a"] }
        #expect(sut.loadingState == .allDataLoaded)
    }

    @Test("A tab picked while the retried feed is still loading shows only its own events")
    func tabPickedDuringRetryKeepsItsOwnEvents() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.queuedCategoryResults = [.failure(EventsTestError.unavailable)]
        provider.categoryList = [Self.category(1), Self.category(2)]
        provider.slowEventCategories = [1]
        provider.eventPages = [
            .init(category: 1, cursor: nil): Self.page(["a"]),
            .init(category: 2, cursor: nil): Self.page(["b"]),
        ]
        let sut = Self.makeSUT(provider: provider)

        try await settle { sut.loadingState == .error }

        sut.handleViewAction(.retry)
        try await settle { !sut.categories.isEmpty }

        sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")

        try await settle { Self.cardIDs(sut) == ["b"] }
        try await Task.sleep(nanoseconds: PolymarketAPIProviderStub.slowEventsDelay * 3 / 2)

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

        try await settle { Self.cardIDs(sut) == ["a"] }

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

        try await settle { context.provider.eventsRequests.count == 2 }
        #expect(context.provider.eventsRequests.last?.cursor == nil)
        #expect(context.provider.eventsRequests.last?.category == 1)
    }

    @Test("A fresh page and a page off screen are not asked for")
    func freshOrHiddenPagesAreNotRefreshed() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: false))
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "elsewhere", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 1)

        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await settle { context.provider.eventsRequests.count == 2 }
    }

    @Test("A failed later page keeps the feed as it is and is asked again on the next tick")
    func failedLaterPageKeepsTheFeed() async throws {
        let context = try await Self.makePollingContext(pages: [
            .init(category: 1, cursor: nil): Self.page(["a"], cursor: "c1"),
            .init(category: 1, cursor: "c1"): Self.page(["b"]),
        ])

        context.sut.handleViewAction(.loadNextPage)
        try await settle { Self.cardIDs(context.sut) == ["a", "b"] }

        context.provider.eventErrors = [.init(category: 1, cursor: "c1"): Self.badGateway]
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "b", isVisible: true))

        try await settle { context.provider.eventsRequests.count == 3 }
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 3)
        #expect(context.provider.eventsRequests.last?.cursor == "c1")
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
        try await settle(timeout: .seconds(5)) { context.sut.loadingState == .paginationError }

        context.provider.eventErrors = [:]
        context.sut.handleViewAction(.retryNextPage)

        try await settle { Self.cardIDs(context.sut) == ["a", "b"] }
        #expect(context.provider.eventsRequests.map(\.cursor) == [nil, "c1", "c1", "c1"])
    }

    @Test("A failed first page keeps the feed as it is")
    func failedFirstPageIsNotAStaleCursor() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.provider.eventErrors = [.init(category: 1, cursor: nil): Self.badGateway]
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))

        try await settle { context.provider.eventsRequests.count == 2 }
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 2)
        #expect(Self.cardIDs(context.sut) == ["a"])
    }

    @Test("Three failed refreshes in a row report outdated data once, and again only after the cooldown")
    func repeatedFailuresReportOutdatedData() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.provider.eventErrors = [.init(category: 1, cursor: nil): Self.unavailable]

        try await Self.failRefresh(context, expectingRequests: 2)
        try await Self.failRefresh(context, expectingRequests: 3)
        try await Self.failRefresh(context, expectingRequests: 4)
        try await settle { context.outdatedDataLog.reports == 1 }

        try await Self.failRefresh(context, expectingRequests: 5)
        try await Self.failRefresh(context, expectingRequests: 6)
        #expect(context.outdatedDataLog.reports == 1)

        context.clock.advance(by: 300)
        try await Self.failRefresh(context, expectingRequests: 7)
        try await settle { context.outdatedDataLog.reports == 2 }
    }

    @Test("In background a page coming on screen is not asked for")
    func backgroundPausesRefreshes() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 1)

        context.notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        try await settle { context.provider.eventsRequests.count == 2 }
    }

    @Test("While search is open a page coming on screen is not asked for, closing search asks for it at once")
    func suspendedPollingSkipsRefreshes() async throws {
        let context = try await Self.makePollingContext(pages: [.init(category: 1, cursor: nil): Self.page(["a"])])

        context.sut.setPollingSuspended(true)

        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)

        #expect(context.provider.eventsRequests.count == 1)

        context.sut.setPollingSuspended(false)
        try await settle { context.provider.eventsRequests.count == 2 }
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

        context.provider.slowEventCategories = [1]
        context.provider.eventPages[.init(category: 1, cursor: nil)] = PolymarketEventsPage(
            events: [Self.event(id: "b", title: "stale"), Self.event(id: "a")],
            cursor: nil,
            hasNext: false
        )
        context.clock.advance(by: 21)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        context.notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        try await settle { context.provider.eventsRequests.count == 2 }

        context.sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        try await settle { Self.cardIDs(context.sut) == ["b"] }
        try await Task.sleep(nanoseconds: PolymarketAPIProviderStub.slowEventsDelay * 2)

        #expect(context.sut.eventCards.first?.regularModel?.title == "b")
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
        try await settle { Self.priceTexts(context.sut).first == Self.cents("0.55") }

        cardBeforePoll.onSelect()

        #expect(routable.openedOutcomes.map(\.outcome.probability) == [Decimal(string: "0.55")])
        #expect(routable.openedOutcomes.map(\.market.id) == ["a-market"])
    }

    // MARK: - Live quotes

    @Test("A live quote puts its best ask on the outcome button, an empty ask shows a dash")
    func liveQuoteShowsTheBestAsk() async throws {
        let context = try await Self.makeLiveContext()

        context.stream.push(PolymarketLiveQuotesFixtures.quote("a-m0-yes", bid: "0.36", ask: "0.37"))
        context.stream.push(PolymarketLiveQuotesFixtures.quote("a-m0-no", bid: "0.62"))

        try await settle { Self.priceTexts(context.sut) == [Self.cents("0.37"), BalanceFormatter.defaultEmptyBalanceString] }
    }

    @Test("A batch that changes no price on screen does not republish the cards")
    func unchangedPricesAreNotRepublished() async throws {
        let context = try await Self.makeLiveContext()
        var publishes = 0
        let subscription = context.sut.$eventCards.dropFirst().sink { _ in publishes += 1 }

        context.stream.push(PolymarketLiveQuotesFixtures.quote("a-m0-yes", bid: "0.30", ask: "0.37"))
        try await settle { Self.priceTexts(context.sut).first == Self.cents("0.37") }

        context.stream.push(PolymarketLiveQuotesFixtures.quote("a-m0-yes", bid: "0.31", ask: "0.37"))
        try await Task.sleep(nanoseconds: Self.batchSettle)

        context.stream.push(PolymarketLiveQuotesFixtures.quote("a-m0-yes", bid: "0.31", ask: "0.38"))
        try await settle { Self.priceTexts(context.sut).first == Self.cents("0.38") }

        #expect(publishes == 2)
        withExtendedLifetime(subscription) {}
    }

    @Test("A lost connection brings the prices from the backend back")
    func lostConnectionFallsBackToBackendPrices() async throws {
        let context = try await Self.makeLiveContext()

        context.stream.push(PolymarketLiveQuotesFixtures.quote("a-m0-yes", ask: "0.37"))
        try await settle { Self.priceTexts(context.sut).first == Self.cents("0.37") }

        context.liveQuotes.statuses.push(.waitingToReconnect)

        try await settle { Self.priceTexts(context.sut) == [Self.cents("0.42"), Self.cents("0.58")] }
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
        try await settle { context.liveQuotes.streams.count == 1 }

        context.liveQuotes.streams[0].push(PolymarketLiveQuotesFixtures.quote("1201001-draw-yes", bid: "0.26", ask: "0.27"))

        try await settle {
            context.sut.eventCards.first?.liveGameModel?.outcomes[safe: 1]?.priceText == PolymarketPriceFormatter.wholeCentsText(Decimal(string: "0.27"))
        }
    }

    @Test("When the socket and the feed put a match on the same stage, the card shows the socket score, because the feed score lags behind")
    func socketScoreWinsOnTheSameStage() async throws {
        let context = try await Self.makeGameContext(events: [Games.basketball()])

        context.push(Games.liveGame(Games.basketballGameId, score: "100-101"))

        try await settle { Self.liveScore(context.sut)?.away == "100" }
    }

    @Test("A lost socket brings the score from REST back")
    func lostSocketFallsBackToRest() async throws {
        let context = try await Self.makeGameContext(events: [Games.basketball()])

        context.push(Games.liveGame(Games.basketballGameId, score: "100-101"))
        try await settle { Self.liveScore(context.sut)?.away == "100" }

        context.liveGames.statuses.push(.waitingToReconnect)

        try await settle { Self.liveScore(context.sut)?.away == "98" }
    }

    @Test("After a real reconnection only the pages on screen are asked again, each with its own cursor")
    func reconnectionRefetchesVisiblePages() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.eventPages = [
            .init(category: 1, cursor: nil): PolymarketEventsPage(events: [Games.soccer()], cursor: "c1", hasNext: true),
            .init(category: 1, cursor: "c1"): PolymarketEventsPage(events: [Games.basketball()], cursor: nil, hasNext: false),
        ]
        let context = try await Self.makeGameContext(provider: provider)
        context.sut.handleViewAction(.loadNextPage)
        try await settle { context.sut.eventCards.count == 2 }
        context.sut.handleViewAction(.onEventVisibilityChange(id: "1197295", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)
        let requestsBefore = provider.eventsRequests.count

        context.reconnect()

        try await settle { provider.eventsRequests.count == requestsBefore + 1 }
        try await drain()
        #expect(provider.eventsRequests.dropFirst(requestsBefore).map(\.cursor) == ["c1"])
    }

    @Test("A second reconnection while the first refetch still waits for the backend asks for the page again")
    func secondReconnectionDuringARefetchStillRefetches() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.slowEventCategories = [1]
        provider.slowEventsIgnoreCancellation = true
        let context = try await Self.makeGameContext(events: [Games.basketball()], provider: provider)
        context.sut.handleViewAction(.onEventVisibilityChange(id: "1197295", isVisible: true))
        try await Task.sleep(nanoseconds: Self.visibilitySettle)
        let requestsBefore = provider.eventsRequests.count

        context.reconnect()
        try await settle { provider.eventsRequests.count == requestsBefore + 1 }
        context.reconnect()

        try await settle { provider.eventsRequests.count == requestsBefore + 2 }
    }

    @Test("A match the socket reports started gets its quotes followed before REST catches up")
    func socketStartFollowsQuotes() async throws {
        let match = Games.basketball(isLive: false, score: nil, period: nil)
        let context = try await Self.makeGameContext(events: [match])
        context.sut.handleViewAction(.onEventVisibilityChange(id: match.id, isVisible: true))
        try await drain()
        #expect(context.liveQuotes.streams.isEmpty)

        context.push(Games.liveGame(Games.basketballGameId, score: "2-0", period: "Q1"))

        try await settle { context.liveQuotes.streams.last?.assetIds.contains("1197295-phi") == true }
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
        try await settle { Self.liveScore(context.sut)?.away == "100" }

        #expect(publishes == 1)
        #expect(context.sut.eventCards.last == soccerCard)
        withExtendedLifetime(subscription) {}
    }

    @Test("Coming back to a category from the cache follows its matches again")
    func restoredCategoryFollowsItsMatches() async throws {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [Self.category(1), Self.category(2)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): PolymarketEventsPage(events: [Games.basketball()], cursor: nil, hasNext: false),
            .init(category: 2, cursor: nil): Self.page(["b"]),
        ]
        let context = try await Self.makeGameContext(provider: provider)

        context.sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 2, title: "")
        try await settle { Self.cardIDs(context.sut) == ["b"] }
        context.sut.selectedCategoryTab.wrappedValue = PolymarketCategoryTab(id: 1, title: "")
        try await settle { Self.cardIDs(context.sut) == ["1197295"] }
        try await drain()

        context.push(Games.liveGame(Games.basketballGameId, score: "100-101"))

        try await settle { Self.liveScore(context.sut)?.away == "100" }
    }
}

// MARK: - Helpers

private extension PolymarketEventsBlockViewModelTests {
    static func makeSUT(
        provider: PolymarketAPIProviderStub,
        routable: PolymarketEventOpeningRoutableSpy = PolymarketEventOpeningRoutableSpy.ignored,
        isRegionRestricted: Bool = false,
        notificationCenter: NotificationCenter = NotificationCenter(),
        clock: PollingClock = PollingClock(),
        outdatedDataLog: OutdatedDataLog = OutdatedDataLog(),
        liveQuotes: PolymarketLiveQuotesSourceSpy = PolymarketLiveQuotesSourceSpy(),
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
            liveQuotesTracker: liveQuotes.makeTracker(),
            liveGamesTracker: liveGames.makeTracker(),
            usesPhaseTwoCards: usesPhaseTwoCards,
            isRegionRestricted: { isRegionRestricted },
            routable: routable,
            notificationCenter: notificationCenter,
            now: { clock.now },
            reportOutdatedData: { outdatedDataLog.reports += 1 }
        )
    }

    struct PollingContext {
        let sut: PolymarketEventsBlockViewModel
        let provider: PolymarketAPIProviderStub
        let clock: PollingClock
        let outdatedDataLog: OutdatedDataLog
        let notificationCenter: NotificationCenter
    }

    static let visibilitySettle: UInt64 = 800_000_000
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
        let outdatedDataLog = OutdatedDataLog()
        let notificationCenter = NotificationCenter()
        let sut = makeSUT(
            provider: provider,
            routable: routable,
            notificationCenter: notificationCenter,
            clock: clock,
            outdatedDataLog: outdatedDataLog
        )

        try await settle { !sut.eventCards.isEmpty }

        return PollingContext(
            sut: sut,
            provider: provider,
            clock: clock,
            outdatedDataLog: outdatedDataLog,
            notificationCenter: notificationCenter
        )
    }

    static func failRefresh(_ context: PollingContext, expectingRequests count: Int) async throws {
        context.clock.advance(by: 21)

        try await settle {
            context.sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
            return context.provider.eventsRequests.count == count
        }
    }

    struct LiveContext {
        let sut: PolymarketEventsBlockViewModel
        let liveQuotes: PolymarketLiveQuotesSourceSpy
        let stream: PolymarketLiveStreamSpy<PolymarketOutcomeQuote>
    }

    static let batchSettle: UInt64 = 600_000_000

    static func makeLiveContext() async throws -> LiveContext {
        let provider = PolymarketAPIProviderStub()
        provider.categoryList = [category(1)]
        provider.eventPages = [
            .init(category: 1, cursor: nil): PolymarketEventsPage(events: [PolymarketLiveQuotesFixtures.event(id: "a")], cursor: nil, hasNext: false),
        ]
        let liveQuotes = PolymarketLiveQuotesSourceSpy()
        let sut = makeSUT(provider: provider, liveQuotes: liveQuotes)

        try await settle { cardIDs(sut) == ["a"] }

        liveQuotes.statuses.push(.connected)
        try await settle { liveQuotes.statuses.pulls >= 2 }

        sut.handleViewAction(.onEventVisibilityChange(id: "a", isVisible: true))
        try await settle { liveQuotes.streams.count == 1 }

        return LiveContext(sut: sut, liveQuotes: liveQuotes, stream: liveQuotes.streams[0])
    }

    struct GameContext {
        let sut: PolymarketEventsBlockViewModel
        let liveGames: PolymarketLiveGamesSourceSpy
        let liveQuotes: PolymarketLiveQuotesSourceSpy

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
            provider.eventPages[.init(category: 1, cursor: nil)] = PolymarketEventsPage(events: events, cursor: nil, hasNext: false)
        }

        let liveGames = PolymarketLiveGamesSourceSpy()
        let liveQuotes = PolymarketLiveQuotesSourceSpy()
        let sut = makeSUT(provider: provider, routable: routable, liveQuotes: liveQuotes, liveGames: liveGames, usesPhaseTwoCards: usesPhaseTwoCards)

        try await settle { !sut.eventCards.isEmpty }
        liveGames.statuses.push(.connected)
        try await settle { liveGames.statuses.pulls >= 2 }
        try await drain()

        return GameContext(sut: sut, liveGames: liveGames, liveQuotes: liveQuotes)
    }

    static func liveScore(_ sut: PolymarketEventsBlockViewModel) -> PolymarketLiveGameCard.Score? {
        sut.eventCards.first { $0.id == "1197295" }?.liveGameModel?.score
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
            cursor: cursor,
            hasNext: cursor != nil
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
