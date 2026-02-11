//
//  EarnAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Protocol for logging analytics events related to the Earn feature.
protocol EarnAnalyticsProvider: AddTokenFlowAnalyticsLogger {
    func logPageOpened()
    func logMostlyUsedCarouselScrolled()
    func logBestOpportunitiesFilterNetworkApplied(networkFilterType: String, networkId: String)
    func logBestOpportunitiesFilterTypeApplied(type: String)
    func logOpportunitySelected(token: String, blockchain: String, source: String)
    func logAddTokenScreenOpened(token: String, blockchain: String, source: String)
    func logTokenAdded(token: String, blockchain: String)
    func logPageLoadError(errorCode: String, errorMessage: String)
    func logBestOpportunitiesLoadError(errorCode: String, errorMessage: String)
}
