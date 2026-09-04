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
    let marketCap = MarketCapViewModel()
    let pulse: PulseViewModel

    init(
        pulseDataProvider: PulseDataProvider,
        promotionNotificationsManager: PromotionNotificationsManager,
        routable: any FeedRoutable
    ) {
        promoBanner = PromotionNotificationsViewModel(promotionNotificationsManager: promotionNotificationsManager)
        pulse = PulseViewModel(dataProvider: pulseDataProvider, routable: routable)
    }

    func feedSheetSizeDidChange(to size: ShtorkaSize) {
        promoBanner.onScreenVisibilityChange(isVisible: size != .collapsed)
        pulse.feedSheetSizeDidChange(to: size)
    }
}
