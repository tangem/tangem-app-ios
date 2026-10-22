//
//  RealAssetsFeedBuilder.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct RealAssetsFeedBuilder: FeedTabBuilder {
    func makeTab(context: FeedContext) -> FeedTab {
        .realAssets(
            RealAssetsFeedViewModel(
                promotionNotificationsManager: NewsPromotionNotificationsManager(placement: .realAssets),
                router: RealAssetsFeedRouter(context: context)
            )
        )
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        context: FeedContext
    ) -> FeedSearchTab {
        .realAssets(RealAssetsSearchViewModel(query: query, router: RealAssetsFeedRouter(context: context)))
    }
}
