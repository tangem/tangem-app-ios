//
//  ForYouAnalyticsLogger.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol ForYouAnalyticsLogger:
    PortfolioReviewAnalyticsLogger,
    EarnOpportunitiesAnalyticsLogger,
    ForYouAccountSelectorAnalyticsLogger {
    func logScreenOpened()
}

// MARK: - Portfolio review

protocol PortfolioReviewAnalyticsLogger {
    func logFilterInterval(period: TokenSummaryPeriod)
    func logDiagramTap()
}

// MARK: - Earn opportunities

protocol EarnOpportunitiesAnalyticsLogger {
    func logEarnTokenOpened(tokenItem: TokenItem, product: EarnApyInfo.Product)
    func logExploreAllTokens()
}

// MARK: - Account selector

protocol ForYouAccountSelectorAnalyticsLogger {
    func logAccountFilterOpened()
    func logApplySelected()
}
