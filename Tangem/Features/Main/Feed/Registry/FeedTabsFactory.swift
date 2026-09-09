//
//  FeedTabsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedTabsFactory {
    static func makeFactories() -> [any FeedTabFactory] {
        var factories: [any FeedTabFactory] = [CryptoFeedTabFactory()]

        if FeatureProvider.isAvailable(.realAssets) {
            factories.append(RealAssetsFeedTabFactory())
        }

        factories.append(EarnFeedTabFactory())
        factories.append(PredictionsFeedTabFactory())

        return factories
    }
}
