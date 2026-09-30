//
//  FeedSelectionRoutingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI
import Testing
@testable import Tangem

@Suite("Feed selection routing", .serialized)
@MainActor
struct FeedSelectionRoutingTests {
    @Test("An earn selection opens the Earn tab and preselects the type it names")
    func earnSelectionOpensTheTabAndTheFilter() async {
        await withEarnFilterProvider { filterProvider in
            let feed = makeSUT()

            feed.apply(selection: .earn(type: .yield))

            #expect(feed.tabsViewModel.selectedTab.kind == .earn)
            #expect(feed.tabsViewModel.pages.map(\.tab.kind) == [.earn])
            #expect(filterProvider.currentFilter.type == .yield)
        }
    }

    @Test("An earn selection without a type opens the tab and leaves the filter as it was")
    func earnSelectionWithoutTypeKeepsTheFilter() async {
        await withEarnFilterProvider(initialType: .staking) { filterProvider in
            let feed = makeSUT()

            feed.apply(selection: .earn(type: nil))

            #expect(feed.tabsViewModel.selectedTab.kind == .earn)
            #expect(feed.tabsViewModel.pages.map(\.tab.kind) == [.earn])
            #expect(filterProvider.currentFilter.type == .staking)
        }
    }

    @Test("A second selection moves the feed off the tab the first one opened")
    func laterSelectionMovesTheFeedOn() async {
        await withEarnFilterProvider { _ in
            let feed = makeSUT()

            feed.apply(selection: .earn(type: .staking))
            feed.apply(selection: .crypto(categoryId: nil))

            #expect(feed.tabsViewModel.selectedTab.kind == .predictions)
            #expect(feed.tabsViewModel.pages.map(\.tab.kind) == [.predictions])
        }
    }

    @Test("A selection naming a section this build has no tab for opens the default one")
    func selectionForAMissingSectionOpensTheDefault() async {
        await withEarnFilterProvider { _ in
            let feed = makeSUT()

            feed.apply(selection: .earn(type: .yield))
            feed.apply(selection: .realAssets(categoryId: "commodities"))

            #expect(feed.tabsViewModel.selectedTab.kind == .predictions)
            #expect(feed.tabsViewModel.pages.map(\.tab.kind) == [.predictions])
        }
    }

    @Test("A feed shown on a screen of its own opens on the link's section and starts its content")
    func standaloneFeedOpensOnItsSelection() async {
        await withEarnFilterProvider { filterProvider in
            let widgets = WidgetProviderSpy()
            let feed = makeSUT(
                widgetProviders: [widgets],
                container: StandaloneFeedContainer(),
                selection: .earn(type: .yield)
            )

            #expect(feed.tabsViewModel.selectedTab.kind == .earn)
            #expect(feed.tabsViewModel.pages.map(\.tab.kind) == [.earn])
            #expect(filterProvider.currentFilter.type == .yield)

            await settleContainerReport()
            #expect(widgets.refreshCount == 1)
        }
    }

    @Test("A feed built inside a collapsed sheet holds its content back until the sheet is pulled up")
    func collapsedFeedWaitsToBeOpened() async {
        await withEarnFilterProvider { _ in
            let widgets = WidgetProviderSpy()
            let feed = makeSUT(widgetProviders: [widgets], selection: .earn(type: .yield))

            #expect(feed.tabsViewModel.selectedTab.kind == .earn)

            await settleContainerReport()
            #expect(widgets.refreshCount == 0)
        }
    }
}

// MARK: - Helpers

private extension FeedSelectionRoutingTests {
    /// The container reports its size through `receiveOnMain()`, so what it asks of the feed lands a turn later.
    func settleContainerReport() async {
        try? await Task.sleep(for: .milliseconds(50))
    }

    func makeSUT(
        widgetProviders: [FeedWidgetProvider] = [],
        container: any FeedContainer = FeedContainerStub(),
        selection: FeedSelection? = nil
    ) -> FeedViewModel {
        let earn = EarnFeedViewModel(
            promotionNotificationsManager: PromotionNotificationsManagerStub(),
            router: EarnRouterStub()
        )

        let searchBarViewModel = FeedSearchBarViewModel()

        return FeedViewModel(
            searchBarViewModel: searchBarViewModel,
            searchViewModel: FeedSearchViewModel(
                searchBarViewModel: searchBarViewModel,
                resultsQuery: .init(""),
                tabsViewModel: FeedSearchTabsViewModel(tabs: [.predictions]),
                historyProvider: HistoryProviderStub(),
                marketViewModel: CryptoSearchViewModel(
                    query: searchBarViewModel.queryPublisher,
                    history: HistoryProviderStub(),
                    router: CryptoRouterStub(),
                    marketsProvider: MarketsProviderStub()
                )
            ),
            tabsViewModel: FeedTabsViewModel(tabs: [.predictions, .earn(earn)]),
            widgetsViewModel: FeedWidgetsViewModel(
                providers: widgetProviders,
                analytics: FeedWidgetsAnalytics(container: container)
            ),
            container: container,
            selection: selection
        )
    }

    func withEarnFilterProvider(
        initialType: EarnFilterType = .all,
        _ body: (EarnDataFilterProvider) async -> Void
    ) async {
        await InjectedDependenciesIsolation.shared.run {
            let previous = InjectedValues[\.earnDataFilterProvider]
            let provider = EarnDataFilterProvider(initialFilterType: initialType)
            InjectedValues[\.earnDataFilterProvider] = provider

            defer { InjectedValues[\.earnDataFilterProvider] = previous }

            await body(provider)
        }
    }
}

// MARK: - Stubs

private final class PromotionNotificationsManagerStub: PromotionNotificationsManager {
    var notificationInputs: [NotificationViewInput] { get async { [] } }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        Empty<[NotificationViewInput], Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    func loadPromotions() async {}
    func setupManager(with delegate: NotificationTapDelegate?) {}
    func dismissNotification(with id: NotificationViewId) {}
}

private final class EarnRouterStub: EarnFeedRoutable {
    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {}
    func openPortfolioToken(_ walletModel: any WalletModel) {}
    func openNetworksFilter() {}
    func openTypesFilter() {}
}

private final class CryptoRouterStub: CryptoFeedRoutable {
    func openToken(_ token: MarketsTokenModel) {}
    func openPulseTagFilter(with input: PulseTagFilterInput) {}
    func openMarketCapInfo(subject: MarketCapInfoSubject) {}
    func openPortfolioToken(_ walletModel: any WalletModel) {}
}

private final class MarketsProviderStub: FeedSearchProvider {
    typealias Item = MarketsTokenModel

    var statePublisher: AnyPublisher<FeedSearchProviderState<MarketsTokenModel>, Never> {
        Empty<FeedSearchProviderState<MarketsTokenModel>, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    func search(_ query: String) {}
    func reset() {}
}

private final class HistoryProviderStub: FeedSearchHistoryProvider {
    var historyPublisher: AnyPublisher<FeedSearchHistory, Never> {
        Empty<FeedSearchHistory, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    func save(query: String) {}
    func save(token: MarketsTokenModel) {}
    func remove(_ query: FeedRecentQuery) {}
    func clear() {}
}

private final class WidgetProviderSpy: FeedWidgetProvider {
    private(set) var refreshCount = 0

    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        Empty<FeedWidget?, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    func refresh() { refreshCount += 1 }
    func select() {}
}

private final class FeedContainerStub: FeedContainer {
    let isPresented = true
    let size: ShtorkaSize = .collapsed

    var sizePublisher: AnyPublisher<ShtorkaSize, Never> {
        Empty<ShtorkaSize, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    var contentCollapsedPublisher: AnyPublisher<Bool, Never> {
        Empty<Bool, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    var dismissPublisher: AnyPublisher<Void, Never> {
        Empty<Void, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    func expand() {}

    func setNavigationActive(_ isActive: Bool) {}

    func setSearchActive(_ isActive: Bool) {}
}
