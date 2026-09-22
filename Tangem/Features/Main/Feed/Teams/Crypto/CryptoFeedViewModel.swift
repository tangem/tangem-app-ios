//
//  CryptoFeedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class CryptoFeedViewModel: ObservableObject {
    let promoBanner: PromotionNotificationsViewModel
    let marketCap: MarketCapViewModel
    let pulse: PulseViewModel

    init(
        pulseDataProvider: PulseDataProvider,
        promotionNotificationsManager: PromotionNotificationsManager,
        router: any CryptoFeedRoutable
    ) {
        promoBanner = PromotionNotificationsViewModel(promotionNotificationsManager: promotionNotificationsManager)
        marketCap = MarketCapViewModel(router: router)
        pulse = PulseViewModel(dataProvider: pulseDataProvider, router: router)
    }

    func feedSheetSizeDidChange(to size: ShtorkaSize) {
        marketCap.feedSheetSizeDidChange(to: size)
        pulse.feedSheetSizeDidChange(to: size)
    }
}
