//
//  EarnFeedBuilder.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct EarnFeedBuilder: FeedTabBuilder {
    func makeTab(context: FeedContext) -> FeedTab {
        .earn(
            EarnFeedViewModel(
                promotionNotificationsManager: NewsPromotionNotificationsManager(placement: .earn),
                router: EarnFeedRouter(context: context)
            )
        )
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        context: FeedContext
    ) -> FeedSearchTab {
        .earn(EarnSearchViewModel(query: query, router: EarnFeedRouter(context: context)))
    }
}
