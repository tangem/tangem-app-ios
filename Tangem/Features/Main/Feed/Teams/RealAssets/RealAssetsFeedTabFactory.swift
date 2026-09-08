//
//  RealAssetsFeedTabFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct RealAssetsFeedTabFactory: FeedTabFactory {
    func makeTab(navigation: any FeedRoutable) -> FeedTab {
        .realAssets(RealAssetsFeedViewModel(routable: navigation))
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        navigation: any FeedRoutable
    ) -> FeedSearchTab {
        .realAssets
    }
}
