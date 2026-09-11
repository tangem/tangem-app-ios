//
//  EarnFeedBuilder.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct EarnFeedBuilder: FeedTabBuilder {
    func makeTab(context: FeedContext) -> FeedTab {
        .earn(EarnFeedViewModel(router: EarnFeedRouter(context: context)))
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        context: FeedContext
    ) -> FeedSearchTab {
        .earn
    }
}
