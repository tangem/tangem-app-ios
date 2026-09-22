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
        shtorkaActions: any MainShtorkaViewActionProvider,
        widgetsRouter: FeedWidgetsRoutable
    ) -> FeedViewModel {
        let searchBarViewModel = FeedSearchBarViewModel()
        let historyProvider = CommonFeedSearchHistoryProvider(storage: CommonFeedSearchHistoryStorage())

        let tabs = tabBuilders.map { $0.makeTab(context: context) }
        let searchTabs = tabBuilders.map { builder in
            builder.makeSearchTab(
                query: searchBarViewModel.queryPublisher,
                history: historyProvider,
                context: context
            )
        }

        return FeedViewModel(
            searchBarViewModel: searchBarViewModel,
            searchViewModel: FeedSearchViewModel(
                searchBarViewModel: searchBarViewModel,
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
            widgetsViewModel: FeedWidgetsViewModel(providers: FeedWidgetsRegistry.makeProviders(router: widgetsRouter)),
            shtorkaActions: shtorkaActions
        )
    }
}
