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
        let portfolioTokenRouter = FeedPortfolioTokenRouter(context: context)
        let searchPortfolioProvider = FeedSearchPortfolioProvider(
            query: resultsQuery.eraseToAnyPublisher(),
            onSelect: portfolioTokenRouter.open
        )

        let tabs = tabBuilders.map { $0.makeTab(context: context) }
        let searchTabs = tabBuilders.map { builder in
            builder.makeSearchTab(
                query: resultsQuery.eraseToAnyPublisher(),
                portfolioProvider: searchPortfolioProvider,
                context: context
            )
        }

        return FeedViewModel(
            searchBarViewModel: searchBarViewModel,
            searchViewModel: FeedSearchViewModel(
                searchBarViewModel: searchBarViewModel,
                resultsQuery: resultsQuery,
                tabsViewModel: FeedSearchTabsViewModel(tabs: searchTabs)
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
