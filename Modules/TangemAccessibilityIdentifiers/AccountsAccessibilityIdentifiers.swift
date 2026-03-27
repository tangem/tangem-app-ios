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

    // MARK: - Account Form

    /// Account name text field on the account form screen.
    public static let accountFormNameInput = "accountFormNameInput"

    /// Main action button on the account form screen (Add account / Save).
    public static let accountFormMainButton = "accountFormMainButton"

    // MARK: - Wallet Settings

    /// "Add account" button in wallet settings accounts section.
    public static let walletSettingsAddAccountButton = "walletSettingsAddAccountButton"

    /// "Archived Accounts" button in wallet settings accounts section footer.
    public static let walletSettingsArchivedAccountsButton = "walletSettingsArchivedAccountsButton"

    // MARK: - Account Details

    /// Edit button on the Account Details screen.
    public static let accountDetailsEditButton = "accountDetailsEditButton"

    /// Archive button on the Account Details screen.
    public static let accountDetailsArchiveButton = "accountDetailsArchiveButton"

    /// Account name label on the Account Details screen.
    public static let accountDetailsAccountName = "accountDetailsAccountName"
}
