//
//  CryptoFeedTabFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CryptoFeedTabFactory: FeedTabFactory {
    func makeTab(navigation: any FeedRoutable) -> FeedTab {
        .crypto(
            CryptoFeedViewModel(
                pulseDataProvider: CommonPulseDataProvider(),
                promotionNotificationsManager: NewsPromotionNotificationsManager(),
                routable: navigation
            )
        )
    }
}
