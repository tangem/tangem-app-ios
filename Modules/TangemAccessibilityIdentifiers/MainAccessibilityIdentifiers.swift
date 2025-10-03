//
//  MainAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum MainAccessibilityIdentifiers {
    public static let buyTitle = "mainBuyTitle"
    public static let exchangeTitle = "mainExchangeTitle"
    public static let sellTitle = "mainSellTitle"
    public static let tokensList = "mainTokensList"
    public static let organizeTokensButton = "mainOrganizeTokensButton"
    public static let tokenTitle = "mainTokenTitle"
    public static let detailsButton = "mainDetailsButton"
    public static let headerCardImage = "mainHeaderCardImage"
    public static let tokenItemEarnBadge = "tokenItemEarnBadge"
    public static let developerCardBanner = "mainDeveloperCardBanner"
    public static let mandatorySecurityUpdateBanner = "mainMandatorySecurityUpdateBanner"
    public static let totalBalance = "mainTotalBalance"
    public static let refreshSpinner = "mainRefreshSpinner"
    public static let refreshStateRefreshing = "mainRefreshStateRefreshing"
    public static let refreshStateIdle = "mainRefreshStateIdle"

    /// Token-specific identifiers
    public static func tokenBalance(for tokenName: String) -> String {
        return "mainTokenBalance_\(tokenName)"
    }
}
