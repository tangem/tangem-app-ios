//
//  CommonUIAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum CommonUIAccessibilityIdentifiers {
    public static let decimalNumberTextField = "commonUIDecimalNumberTextField"
    public static let grabber = "commonUIGrabber"
    public static let closeButton = "commonUICloseButton"
    public static let backButton = "commonUIBackButton"
    public static let addButton = "commonUIAddButton"
    public static let shareButton = "commonUIShareButton"

    /// Entity summary view components
    public static let entityProviderName = "commonUIEntityProviderName"

    // Notification view components
    public static let notificationTitle = "commonUINotificationTitle"
    public static let notificationMessage = "commonUINotificationMessage"
    public static let notificationIcon = "commonUINotificationIcon"
    public static let notificationDismissButton = "commonUINotificationDismissButton"
    public static let notificationButton = "commonUINotificationButton"

    // Yield module notification
    public static let yieldModuleNotificationTitle = "yieldModuleNotificationTitle"
    public static let yieldModuleNotificationMessage = "yieldModuleNotificationMessage"
    public static let yieldModuleNotificationIcon = "yieldModuleNotificationIcon"
    public static let yieldModuleNotificationDismissButton = "yieldModuleNotificationDismissButton"
    public static let yieldModuleNotificationButton = "yieldModuleNotificationButton"

    public static let retryButton = "commonRetryButton"

    /// Token selector
    public static let tokenSelectorItemPrefix = "commonUITokenSelectorItem_"

    public static func tokenSelectorItem(name: String) -> String {
        "\(tokenSelectorItemPrefix)\(name)"
    }

    /// Account selector
    public static func accountSelectorCell(name: String) -> String {
        "commonUIAccountSelectorCell_\(name)"
    }

    // Addresses info
    public static let addressesInfoButton = "commonUIAddressesInfoButton"
    public static let addressesInfoCopyButton = "commonUIAddressesInfoCopyButton"
    public static let addressesInfoText = "commonUIAddressesInfoText"
}
