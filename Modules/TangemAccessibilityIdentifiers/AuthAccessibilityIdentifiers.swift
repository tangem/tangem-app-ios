//
//  AuthAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum AuthAccessibilityIdentifiers {
    public static let title = "authTitle"
    public static let subtitle = "authSubtitle"
    public static let addWalletButton = "authAddWalletButton"
    public static let walletsList = "authWalletsList"
    public static let biometricsUnlockButton = "authBiometricsUnlockButton"

    public static let walletItemPrefix = "authWalletItem_"

    /// Wallet item identifier - uses wallet name for uniqueness
    public static func walletItem(walletName: String) -> String {
        return "\(walletItemPrefix)\(walletName)"
    }
}
