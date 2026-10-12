//
//  FeedWidgetsRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedWidgetsRegistry {
    static func makeProviders(
        context: FeedContext,
        container: any FeedContainer,
        host: FeedHostRoutable?,
        widgetSheetPresenter: FeedWidgetSheetPresenter
    ) -> [FeedWidgetProvider] {
        let forYouRouter = ForYouFeedRouter(context: context)

        var providers: [FeedWidgetProvider] = [
            ForYouWidgetProvider(router: forYouRouter),
            AddAccountWidgetProvider(router: AccountsFeedRouter(context: context, host: host, widgetSheetPresenter: widgetSheetPresenter)),
        ]

        if let host {
            providers.append(TangemPayWidgetProvider(router: TangemPayFeedRouter(host: host)))
        }

        providers.append(EarnWidgetProvider(router: EarnWidgetRouter(navigation: context.navigation, forYouRouter: forYouRouter)))
        providers.append(ReferralWidgetProvider(router: ReferralFeedRouter(context: context, widgetSheetPresenter: widgetSheetPresenter)))

        if FeatureProvider.isAvailable(.polymarket) {
            providers.append(PolymarketWidgetProvider(router: PredictionsFeedRouter(context: context, container: container)))
        }

        if FeatureProvider.isAvailable(.collectibles) {
            providers.append(CollectiblesWidgetProvider(router: CollectiblesFeedRouter(context: context, widgetSheetPresenter: widgetSheetPresenter)))
        }

        return providers
    }
}
