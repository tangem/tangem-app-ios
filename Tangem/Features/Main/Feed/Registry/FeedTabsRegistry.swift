//
//  FeedTabsRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedTabsRegistry {
    static func makeBuilders() -> [any FeedTabBuilder] {
        var builders: [any FeedTabBuilder] = [CryptoFeedBuilder()]

        if FeatureProvider.isAvailable(.realAssets) {
            builders.append(RealAssetsFeedBuilder())
        }

        builders.append(EarnFeedBuilder())

        return builders
    }
}
