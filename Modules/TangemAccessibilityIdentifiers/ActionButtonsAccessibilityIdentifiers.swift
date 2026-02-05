//
//  ActionButtonsAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum ActionButtonsAccessibilityIdentifiers {
    private static let prefix = "actionButtons"
    /// Action buttons
    public static let buyButton = "\(prefix)Buy"
    public static let copyAddressButton = "\(prefix)CopyAddress"
    public static let receiveButton = "\(prefix)Receive"
    public static let sendButton = "\(prefix)Send"
    public static let swapButton = "\(prefix)Swap"
    public static let sellButton = "\(prefix)Sell"
    public static let analyticsButton = "\(prefix)Analytics"

    /// Toast notifications
    public static let addressCopiedToast = "\(prefix)AddressCopiedToast"
    public static let addressCopiedToastTitle = "\(prefix)AddressCopiedToastTitle"
    public static let addressCopiedToastMessage = "\(prefix)AddressCopiedToastMessage"

    /// Buy token selector screen
    public static let buyTokenSelectorTokensList = "\(prefix)BuyTokenSelectorTokensList"
}
