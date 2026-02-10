//
//  MarketsAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum MarketsAccessibilityIdentifiers {
    public static let listedOnExchanges = "marketsTokenDetailsListedOnExchanges"
    public static let listedOnExchangesTitle = "marketsTokenDetailsListedOnExchangesTitle"
    public static let listedOnExchangesEmptyText = "marketsTokenDetailsListedOnExchangesEmptyText"

    public static let exchangesListTitle = "marketsExchangesListTitle"
    public static let exchangesListExchangeName = "marketsExchangesListExchangeName"
    public static let exchangesListExchangeLogo = "marketsExchangesListExchangeLogo"
    public static let exchangesListTradingVolume = "marketsExchangesListTradingVolume"
    public static let exchangesListType = "marketsExchangesListType"
    public static let exchangesListTrustScore = "marketsExchangesListTrustScore"
    public static let exchangesListTryAgainButton = "marketsExchangesListTryAgainButton"

    public static let marketsListTokenCurrencyLabel = "marketsListTokenCurrencyLabel"
    public static let marketsListTokenNameLabel = "marketsListTokenNameLabel"
    public static let marketsTokensUnderCapExpandButton = "marketsTokensUnderCapExpandButton"
    public static let marketsSearchNoResultsLabel = "marketsSearchNoResultsLabel"

    public static let marketsListTokenPriceChange = "marketsListTokenPriceChange"
    public static let marketsListTokenChart = "marketsListTokenChart"
    public static let marketsListTokenPrice = "marketsListTokenPrice"
    public static let marketsListTokenRating = "marketsListTokenRating"
    public static let marketsListTokenMarketCap = "marketsListTokenMarketCap"
    public static let marketsListTokenIcon = "marketsListTokenIcon"

    public static func marketsIntervalSegment(_ intervalId: String) -> String {
        "marketsIntervalSegment_\(intervalId)"
    }

    public static func marketsListTokenItem(uniqueId: String) -> String {
        return "marketsListTokenItem_\(uniqueId)"
    }

    public static let marketsSortButton = "marketsSortButton"

    public static func marketsSortOption(_ orderType: String) -> String {
        "marketsSortOption_\(orderType)"
    }

    // MARK: - Security Score

    public static let securityScoreBlock = "marketsTokenDetailsSecurityScoreBlock"
    public static let securityScoreValue = "marketsTokenDetailsSecurityScoreValue"
    public static let securityScoreRatingStars = "marketsTokenDetailsSecurityScoreRatingStars"
    public static let securityScoreReviewsCount = "marketsTokenDetailsSecurityScoreReviewsCount"
    public static let securityScoreInfoButton = "marketsTokenDetailsSecurityScoreInfoButton"
    public static let securityScoreDetailsTitle = "marketsTokenDetailsSecurityScoreDetailsTitle"
    public static let securityScoreDetailsProviderLink = "marketsTokenDetailsSecurityScoreDetailsProviderLink"
    public static let marketsSeeAllButton = "marketsSeeAllButton"
}
