//
//  RealAssetsFeedBuilder.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct RealAssetsFeedBuilder: FeedTabBuilder {
    func makeTab(context: FeedContext) -> FeedTab {
        .realAssets(RealAssetsFeedViewModel(router: RealAssetsFeedRouter(context: context)))
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        context: FeedContext
    ) -> FeedSearchTab {
        .realAssets
    }
}
