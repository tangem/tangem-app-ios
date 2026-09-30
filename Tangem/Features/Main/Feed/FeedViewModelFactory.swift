//
//  FeedViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct FeedViewModelFactory {
    private let tabBuilders = FeedTabsRegistry.makeBuilders()

    func makeViewModel(
        context: FeedContext,
        container: any FeedContainer,
        host: FeedHostRoutable?,
        selection: FeedSelection?,
        widgetSheetPresenter: FeedWidgetSheetPresenter
    ) -> FeedViewModel {
        let searchBarViewModel = FeedSearchBarViewModel()
        let resultsQuery = CurrentValueSubject<String, Never>("")
        let historyProvider = CommonFeedSearchHistoryProvider(storage: CommonFeedSearchHistoryStorage())

        let tabs = tabBuilders.map { $0.makeTab(context: context) }
        let searchTabs = tabBuilders.map { builder in
            builder.makeSearchTab(
                query: resultsQuery.eraseToAnyPublisher(),
                history: historyProvider,
                context: context
            )
        }

        return FeedViewModel(
            searchBarViewModel: searchBarViewModel,
            searchViewModel: FeedSearchViewModel(
                searchBarViewModel: searchBarViewModel,
                resultsQuery: resultsQuery,
                tabsViewModel: FeedSearchTabsViewModel(tabs: searchTabs),
                historyProvider: historyProvider,
                marketViewModel: CryptoSearchViewModel(
                    query: Just("").eraseToAnyPublisher(),
                    searchesOnEmptyQuery: true,
                    history: historyProvider,
                    router: CryptoFeedRouter(context: context)
                )
            ),
            tabsViewModel: FeedTabsViewModel(tabs: tabs),
            widgetsViewModel: FeedWidgetsViewModel(
                providers: FeedWidgetsRegistry.makeProviders(
                    context: context,
                    host: host,
                    widgetSheetPresenter: widgetSheetPresenter
                ),
                analytics: FeedWidgetsAnalytics(container: container)
            ),
            container: container,
            selection: selection
        )
    }
}
