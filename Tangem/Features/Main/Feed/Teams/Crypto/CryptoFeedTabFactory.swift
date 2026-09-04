//
//  CryptoFeedTabFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct CryptoFeedTabFactory: FeedTabFactory {
    func makeTab(navigation: any FeedRoutable) -> FeedTab {
        .crypto(
            CryptoFeedViewModel(
                pulseDataProvider: CommonPulseDataProvider(),
                promotionNotificationsManager: NewsPromotionNotificationsManager(),
                routable: navigation
            )
        )
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        navigation: any FeedRoutable
    ) -> FeedSearchTab {
        .crypto(CryptoSearchViewModel(query: query, history: history, navigation: navigation))
    }
}
