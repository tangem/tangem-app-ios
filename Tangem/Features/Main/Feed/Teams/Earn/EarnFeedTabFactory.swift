//
//  EarnFeedTabFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct EarnFeedTabFactory: FeedTabFactory {
    func makeTab(navigation: any FeedRoutable) -> FeedTab {
        .earn(EarnFeedViewModel(routable: navigation))
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        navigation: any FeedRoutable
    ) -> FeedSearchTab {
        .earn
    }
}
