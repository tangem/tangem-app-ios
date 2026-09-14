//
//  FeedViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeedViewModelFactory {
    private let tabBuilders = FeedTabsRegistry.makeBuilders()

    func makeViewModel(context: FeedContext) -> FeedViewModel {
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
                router: FeedSearchRouter(context: context)
            ),
            tabsViewModel: FeedTabsViewModel(tabs: tabs),
            widgetsViewModel: FeedWidgetsViewModel(widgets: FeedWidgetsFactory.makeWidgets())
        )
    }
}
