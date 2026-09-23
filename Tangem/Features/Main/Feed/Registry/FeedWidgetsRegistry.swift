//
//  FeedWidgetsRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedWidgetsRegistry {
    static func makeProviders(router: FeedWidgetsRoutable) -> [FeedWidgetProvider] {
        var providers: [FeedWidgetProvider] = [
            ForYouWidgetProvider(router: router),
            AddAccountWidgetProvider(router: router),
            TangemPayWidgetProvider(router: router),
            EarnWidgetProvider(router: router),
            ReferralWidgetProvider(router: router),
        ]

        if FeatureProvider.isAvailable(.polymarket) {
            providers.append(PolymarketWidgetProvider(router: router))
        }

        if FeatureProvider.isAvailable(.collectibles) {
            providers.append(CollectiblesWidgetProvider(router: router))
        }

        return providers
    }
}
