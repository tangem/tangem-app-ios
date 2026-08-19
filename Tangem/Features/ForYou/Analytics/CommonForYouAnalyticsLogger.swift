//
//  CommonForYouAnalyticsLogger.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonForYouAnalyticsLogger: ForYouAnalyticsLogger {
    func logScreenOpened() {
        Analytics.log(.forYouScreenOpened)
    }

    func logAccountFilterOpened() {
        Analytics.log(.forYouAccountFilterOpened)
    }

    func logApplySelected() {
        Analytics.log(.forYouApplySelected)
    }

    func logFilterInterval(period: TokenSummaryPeriod) {
        Analytics.log(
            event: .forYouFilterInterval,
            params: [.period: ForYouAnalytics.Period(period).rawValue]
        )
    }

    func logDiagramTap() {
        Analytics.log(.forYouDiagramTap)
    }

    func logExploreAllTokens() {
        Analytics.log(.forYouExploreAllTokens)
    }

    func logEarnTokenOpened(tokenItem: TokenItem, product: EarnApyInfo.Product) {
        Analytics.log(
            event: .forYouEarnTokenOpened,
            params: [
                .token: tokenItem.currencySymbol,
                .blockchain: tokenItem.blockchain.displayName,
                .type: ForYouAnalytics.EarnType(product).rawValue,
            ]
        )
    }
}
