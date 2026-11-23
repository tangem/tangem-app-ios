//
//  PolymarketAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketAccessibilityIdentifiers {
    private static let prefix = "polymarket"

    public static let feedWidget = "\(prefix)FeedWidget"

    public static let onboardingTitle = "\(prefix)OnboardingTitle"
    public static let onboardingActionButton = "\(prefix)OnboardingActionButton"

    public static let mainScreenTitle = "\(prefix)MainScreenTitle"
    public static let overflowMenuButton = "\(prefix)OverflowMenuButton"

    public static let regionRestrictionBanner = "\(prefix)RegionRestrictionBanner"
    public static let regionRestrictionSheet = "\(prefix)RegionRestrictionSheet"

    // MARK: - Add funds flow

    public static let addFundsButton = "\(prefix)AddFundsButton"
    public static let addFundsSheetReceiveOption = "\(prefix)AddFundsSheetReceiveOption"
    public static let addFundsSheetSwapOption = "\(prefix)AddFundsSheetSwapOption"

    // MARK: - Deposit receive screen

    public static let receiveSheetWarningTitle = "\(prefix)ReceiveSheetWarningTitle"
    public static let receiveSheetWarningDescription = "\(prefix)ReceiveSheetWarningDescription"
    public static let receiveSheetLimitsDescription = "\(prefix)ReceiveSheetLimitsDescription"
    public static let receiveSheetHeading = "\(prefix)ReceiveSheetHeading"
    public static let receiveSheetAddress = "\(prefix)ReceiveSheetAddress"
    public static let receiveSheetCopyButton = "\(prefix)ReceiveSheetCopyButton"
    public static let receiveSheetShowQRButton = "\(prefix)ReceiveSheetShowQRButton"
    public static let receiveSheetShareButton = "\(prefix)ReceiveSheetShareButton"

    public static func receiveSheetTokenIcon(symbol: String) -> String {
        "\(prefix)ReceiveSheetTokenIcon_\(symbol)"
    }

    // MARK: - Withdraw flow

    public static let withdrawButton = "\(prefix)WithdrawButton"
}
