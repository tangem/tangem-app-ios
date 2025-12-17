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

    public static func marketsListTokenItem(uniqueId: String) -> String {
        return "marketsListTokenItem_\(uniqueId)"
    }
}
