//
//  FeedWidgetsRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedWidgetsRegistry {
    /// `canOpenHostScreens` — the feed sits on a screen it can hand a tap over to. A widget that exists only for
    /// that hand-off is left out where there is none, rather than shown with nothing behind it.
    static func makeProviders(router: FeedWidgetsRoutable, canOpenHostScreens: Bool) -> [FeedWidgetProvider] {
        var providers: [FeedWidgetProvider] = [
            ForYouWidgetProvider(router: router),
            AddAccountWidgetProvider(router: router),
        ]

        if canOpenHostScreens {
            providers.append(TangemPayWidgetProvider(router: router))
        }

        providers.append(EarnWidgetProvider(router: router))
        providers.append(ReferralWidgetProvider(router: router))

        if FeatureProvider.isAvailable(.polymarket) {
            providers.append(PolymarketWidgetProvider(router: router))
        }

        if FeatureProvider.isAvailable(.collectibles) {
            providers.append(CollectiblesWidgetProvider(router: router))
        }

        return providers
    }
}
