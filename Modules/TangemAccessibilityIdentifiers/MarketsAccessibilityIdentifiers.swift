//
//  MarketsAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum MarketsAccessibilityIdentifiers {
    public static let tokenDetailsSubscribeButton = "marketsTokenDetailsSubscribeButton"

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

    public static func marketsIntervalButton(_ selectedIntervalId: String) -> String {
        "marketsIntervalButton_\(selectedIntervalId)"
    }

    public static func marketsListTokenItem(uniqueId: String) -> String {
        return "marketsListTokenItem_\(uniqueId)"
    }

    public static func marketsFeaturedAssetItem(uniqueId: String) -> String {
        "marketsFeaturedAssetItem_\(uniqueId)"
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

    // MARK: - Portfolio Account Header

    /// Account header in Markets portfolio container.
    /// Format: `marketsPortfolioAccountHeader_<accountName>`
    public static func marketsPortfolioAccountHeader(accountName: String) -> String {
        "marketsPortfolioAccountHeader_\(accountName)"
    }

    // MARK: - Portfolio Token Item

    /// Token item button in Markets portfolio container (used to expand quick actions).
    /// Format: `marketsPortfolioTokenItem_<tokenName>`
    public static func marketsPortfolioTokenItem(tokenName: String) -> String {
        "marketsPortfolioTokenItem_\(tokenName)"
    }

    // MARK: - Real Assets Filter

    public static func marketsRealAssetsFilterCategoryOption(_ categoryCode: String) -> String {
        "marketsRealAssetsFilterCategoryOption_\(categoryCode)"
    }

    public static func marketsRealAssetsFilterSectorChip(_ sectorCode: String) -> String {
        "marketsRealAssetsFilterSectorChip_\(sectorCode)"
    }

    public static let marketsRealAssetsFilterResetButton = "marketsRealAssetsFilterResetButton"
    public static let marketsRealAssetsFilterApplyButton = "marketsRealAssetsFilterApplyButton"
    public static let marketsRealAssetsFilterCloseButton = "marketsRealAssetsFilterCloseButton"

    // MARK: - Pulse Tag Filter

    public static let marketsPulseTagChip = "marketsPulseTagChip"
    public static let marketsPulseTagFilterSearchField = "marketsPulseTagFilterSearchField"
    public static let marketsPulseTagFilterResetButton = "marketsPulseTagFilterResetButton"
    public static let marketsPulseTagFilterApplyButton = "marketsPulseTagFilterApplyButton"
    public static let marketsPulseTagFilterCloseButton = "marketsPulseTagFilterCloseButton"

    public static func marketsPulseTagFilterFeaturedChip(_ tagId: String) -> String {
        "marketsPulseTagFilterFeaturedChip_\(tagId)"
    }

    public static func marketsPulseTagFilterCategoryOption(_ tagId: String) -> String {
        "marketsPulseTagFilterCategoryOption_\(tagId)"
    }
}
