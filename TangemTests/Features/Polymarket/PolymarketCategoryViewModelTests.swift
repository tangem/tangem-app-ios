//
//  PolymarketCategoryViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket category screen", .timeLimit(.minutes(1)))
struct PolymarketCategoryViewModelTests {
    @Test("Pulling the category to refresh reads fast trading again")
    func pullToRefreshReadsFastTrading() async {
        let fastTrading = PolymarketFastTradingServiceSpy()
        let sut = makeSUT(fastTrading: fastTrading)

        await sut.refresh()

        #expect(fastTrading.refreshes.recorded.count == 1)
    }

    @Test("The category asks to activate fast trading instead of warning about foreign signers")
    func categoryLeavesOutForeignSigners() async {
        let foreignSigner = PolymarketSessionSigner(
            address: "0xf0e1000000000000000000000000000000000009",
            scopes: ["CLOB"],
            validUntil: Fixture.validUntil
        )
        let fastTrading = PolymarketFastTradingServiceSpy(state: .loaded(Fixture.assess(keys: [], signers: [foreignSigner])))
        let sut = makeSUT(fastTrading: fastTrading)

        #expect(await sut.$fastTradingBanner.firstValue { $0 != nil } == .activate)
    }

    @Test(
        "A tapped banner opens its own screen even when the shown banner has changed since",
        arguments: [
            (PolymarketFastTradingBanner.foreignSigners, Route.settings),
            (.activate, .activation),
            (.reactivate, .activation),
            (.extend(daysLeft: 3), .activation),
        ]
    )
    func tappedBannerOpensItsScreen(_ banner: PolymarketFastTradingBanner, _ route: Route) async {
        let routable = CategoryRoutableSpy()
        let sut = makeSUT(fastTrading: Self.showingActivation(), coordinator: routable)
        await sut.$fastTradingBanner.firstValue { $0 == .activate }

        sut.handleViewAction(.performFastTradingBannerAction(banner))

        #expect(routable.routes == [route])
    }

    @Test("Closing a banner closes the tapped one even when the shown banner has changed since")
    func closingDismissesTheTappedBanner() async {
        let fastTrading = Self.showingActivation()
        let sut = makeSUT(fastTrading: fastTrading)
        await sut.$fastTradingBanner.firstValue { $0 == .activate }

        sut.handleViewAction(.dismissFastTradingBanner(.extend(daysLeft: 3)))

        #expect(fastTrading.dismissedBanners == [.extend(daysLeft: 3)])
    }
}

// MARK: - Arguments

extension PolymarketCategoryViewModelTests {
    enum Route: Equatable {
        case close
        case settings
        case activation
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketCategoryViewModelTests {
    static func showingActivation() -> PolymarketFastTradingServiceSpy {
        PolymarketFastTradingServiceSpy(state: .loaded(Fixture.assess(keys: [])))
    }

    func makeSUT(
        fastTrading: PolymarketFastTradingBannerProviding,
        coordinator: PolymarketCategoryRoutable? = nil
    ) -> PolymarketCategoryViewModel {
        let category = PolymarketCategory(id: 1, label: "Sports", icon: nil)
        let eventsRefreshCenter = PolymarketMainRefreshCenter()

        let eventsViewModel = PolymarketEventsBlockViewModel(
            source: .category(category),
            apiProvider: PolymarketAPIProviderStub(),
            refreshCenter: eventsRefreshCenter,
            activityHandler: PolymarketMainActivityHandler(
                fundsArrivalTracker: PolymarketFundsArrivalTracker(balancePublisher: .empty),
                refreshCenter: eventsRefreshCenter
            ),
            liveQuotesTracker: PolymarketLiveQuotesSourceSpy().makeTracker(),
            liveGamesTracker: PolymarketLiveGamesSourceSpy().makeTracker(),
            usesPhaseTwoCards: false,
            showsSubcategories: false,
            isRegionRestricted: { false },
            routable: PolymarketEventOpeningRoutableSpy.ignored,
            appStateObserver: AppStateObserverStub(),
            delayProvider: HoldingDelayProviderSpy(holdThreshold: 0),
            reportOutdatedData: {}
        )

        return PolymarketCategoryViewModel(
            category: category,
            eventsViewModel: eventsViewModel,
            refreshCenter: PolymarketMainRefreshCenter(),
            fastTrading: fastTrading,
            coordinator: coordinator
        )
    }
}

// MARK: - Stubs

private final class CategoryRoutableSpy: PolymarketCategoryRoutable {
    private(set) var routes: [PolymarketCategoryViewModelTests.Route] = []

    func closeCategory() {
        routes.append(.close)
    }

    func openSettings() {
        routes.append(.settings)
    }

    func openFastTradingActivation() {
        routes.append(.activation)
    }
}
