//
//  AccountsAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum AccountsAccessibilityIdentifiers {
    /// Account row button in wallet settings (accounts list).
    /// Format: `walletSettingsAccount_<accountName>`
    public static func walletSettingsAccountRow(accountName: String) -> String {
        "walletSettingsAccount_\(accountName)"
    }

    /// Manage tokens button on Account Details screen.
    public static let accountDetailsManageTokensButton = "accountDetailsManageTokensButton"
}
