//
//  CryptoFeedBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct CryptoFeedBuilder: FeedTabBuilder {
    func makeTab(context: FeedContext) -> FeedTab {
        .crypto(
            CryptoFeedViewModel(
                pulseDataProvider: CommonPulseDataProvider(),
                promotionNotificationsManager: NewsPromotionNotificationsManager(placement: .crypto),
                router: CryptoFeedRouter(context: context)
            )
        )
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        context: FeedContext
    ) -> FeedSearchTab {
        .crypto(CryptoSearchViewModel(query: query, router: CryptoFeedRouter(context: context)))
    }
}
