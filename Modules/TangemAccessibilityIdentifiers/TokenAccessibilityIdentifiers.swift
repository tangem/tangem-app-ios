//
//  TokenAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum TokenAccessibilityIdentifiers {
    public static let moreButton = "tokenMoreButton"
    public static let hideTokenButton = "tokenHideButton"
    public static let actionButtonsList = "tokenActionButtonsList"
    public static let insufficientFeeCurrencyBanner = "tokenInsufficientFeeCurrencyBanner"
    public static let feeCurrencyNavigationButton = "tokenFeeCurrencyNavigationButton"
    public static let tokenNameLabel = "tokenNameLabel"

    /// Staking related elements
    public static let nativeStakingBlock = "tokenNativeStakingBlock"
    public static let nativeStakingTitle = "tokenNativeStakingTitle"
    public static let nativeStakingChevron = "tokenNativeStakingChevron"

    public static let topUpWalletBanner = "tokenTopUpWalletBanner"
    public static let notEnoughFeeForTransactionBanner = "tokenNotEnoughFeeForTransactionBanner"

    /// Balance elements
    public static let totalBalance = "tokenTotalBalance"
    public static let availableBalance = "tokenAvailableBalance"
    public static let stakingBalance = "tokenStakingBalance"

    /// Network selector elements
    public static let mainNetworkSwitch = "tokenMainNetworkSwitch"
    public static let continueButton = "tokenContinueButton"

    public static func networkSwitch(for networkName: String) -> String {
        return "tokenNetworkSwitch_\(networkName)"
    }

    public static func networkCell(for networkName: String) -> String {
        return "tokenNetworkCell_\(networkName)"
    }

    public static let addTokenButton = "tokenAddTokenButton"
    public static let getTokenLaterButton = "tokenGetTokenLaterButton"
}
