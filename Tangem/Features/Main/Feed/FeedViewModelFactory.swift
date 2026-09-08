//
//  FeedViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeedViewModelFactory {
    private let tabFactories = FeedTabsFactory.makeFactories()

    func makeViewModel(coordinator: any FeedRoutable) -> FeedViewModel {
        let searchBarViewModel = FeedSearchBarViewModel()
        let historyProvider = CommonFeedSearchHistoryProvider(storage: CommonFeedSearchHistoryStorage())

        let tabs = tabFactories.map { $0.makeTab(navigation: coordinator) }
        let searchTabs = tabFactories.map { factory in
            factory.makeSearchTab(
                query: searchBarViewModel.queryPublisher,
                history: historyProvider,
                navigation: coordinator
            )
        }

        return FeedViewModel(
            searchBarViewModel: searchBarViewModel,
            searchViewModel: FeedSearchViewModel(
                searchBarViewModel: searchBarViewModel,
                tabsViewModel: FeedSearchTabsViewModel(tabs: searchTabs),
                navigation: coordinator,
                historyProvider: historyProvider
            ),
            tabsViewModel: FeedTabsViewModel(tabs: tabs),
            widgetsViewModel: FeedWidgetsViewModel(widgets: FeedWidgetsFactory.makeWidgets()),
            routable: coordinator
        )
    }
}
