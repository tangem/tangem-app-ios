//
//  AppsFlyerMarketingActivityHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct AppsFlyerMarketingActivityHandler {
    @Injected(\.marketingActivityBindingService) private var bindingService: MarketingActivityBindingService

    func handle(_ params: AppsFlyerDeepLinkParams) {
        guard let uid = params.marketingActivityUid else {
            return
        }

        bindingService.register(uid: uid)
    }
}
