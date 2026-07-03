//
//  CardSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class CardSettingsScreen: ScreenBase<CardSettingsScreenElement> {
    private lazy var referralButton = button(.referralButton)
    private lazy var deviceSettingsButton = button(.deviceSettings)
    private lazy var addAccountButton = button(.addAccount)
    private lazy var renameWalletRow = anyElement(.renameWalletRow)

    func openReferralProgram() -> ReferralScreen {
        XCTContext.runActivity(named: "Open referral program screen") { _ in
            referralButton.waitAndTap()
            return ReferralScreen(app)
        }
    }

    func openDeviceSettings() -> ScanCardSettingsScreen {
        XCTContext.runActivity(named: "Open device settings") { _ in
            deviceSettingsButton.waitAndTap()
            return ScanCardSettingsScreen(app)
        }
    }

    func selectAccount(_ accName: String) -> AccountSettingsScreen {
        XCTContext.runActivity(named: "Select account: \(accName)") { _ in
            let accountButton = app.buttons[AccountsAccessibilityIdentifiers.walletSettingsAccountRow(accountName: accName)]
            accountButton.waitAndTap()
            return AccountSettingsScreen(app)
        }
    }

    func openArchivedAccounts() -> ArchivedAccountsScreen {
        XCTContext.runActivity(named: "Open archived accounts") { _ in
            let archivedButton = app.buttons[AccountsAccessibilityIdentifiers.walletSettingsArchivedAccountsButton]
            archivedButton.waitAndTap()
            return ArchivedAccountsScreen(app)
        }
    }

    @discardableResult
    func verifyAccountExists(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Verify account '\(accountName)' exists in wallet settings") { _ in
            let accountButton = app.buttons[AccountsAccessibilityIdentifiers.walletSettingsAccountRow(accountName: accountName)]
            waitAndAssertTrue(accountButton, "Account '\(accountName)' should be visible")
            return self
        }
    }

    @discardableResult
    func verifyAccountNotExists(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Verify account '\(accountName)' does not exist in wallet settings") { _ in
            let accountButton = app.buttons[AccountsAccessibilityIdentifiers.walletSettingsAccountRow(accountName: accountName)]
            XCTAssertFalse(
                accountButton.waitForExistence(timeout: .conditional),
                "Account '\(accountName)' should not be visible"
            )
            return self
        }
    }

    @discardableResult
    func verifyArchivedAccountsButtonExists() -> Self {
        XCTContext.runActivity(named: "Verify archived accounts button exists") { _ in
            let archivedButton = app.buttons[AccountsAccessibilityIdentifiers.walletSettingsArchivedAccountsButton]
            waitAndAssertTrue(archivedButton, "Archived accounts button should be visible")
            return self
        }
    }

    @discardableResult
    func verifyArchivedAccountsButtonNotExists() -> Self {
        XCTContext.runActivity(named: "Verify archived accounts button does not exist") { _ in
            let archivedButton = app.buttons[AccountsAccessibilityIdentifiers.walletSettingsArchivedAccountsButton]
            XCTAssertTrue(
                archivedButton.waitForNonExistence(timeout: .robustUIUpdate),
                "Archived accounts button should not be visible"
            )
            return self
        }
    }

    @discardableResult
    func verifyMigrationDialogVisible() -> Self {
        XCTContext.runActivity(named: "Verify migration dialog is visible") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Migration dialog should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyMigrationDialogContains(text: String) -> Self {
        XCTContext.runActivity(named: "Verify migration dialog contains '\(text)'") { _ in
            let alert = app.alerts.firstMatch
            let textElement = alert.staticTexts.element(
                matching: NSPredicate(format: "label CONTAINS[c] %@", text)
            ).firstMatch
            XCTAssertTrue(textElement.exists, "Migration dialog should contain '\(text)'")
            return self
        }
    }

    @discardableResult
    func verifyReferralUnavailable() -> Self {
        XCTContext.runActivity(named: "Verify Referral program is unavailable for current wallet") { _ in
            XCTAssertTrue(referralButton.waitForNonExistence(timeout: .conditional), "Referral program should be unavailable")
            return self
        }
    }

    @discardableResult
    func confirmMigrationDialog() -> Self {
        XCTContext.runActivity(named: "Confirm migration dialog") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Migration dialog should be displayed")
            alert.buttons["Got it"].waitAndTap()
            return self
        }
    }

    func goBackToDetails() -> DetailsScreen {
        XCTContext.runActivity(named: "Go back to Details") { _ in
            app.navigationBars.buttons["Details"].waitAndTap()
            return DetailsScreen(app)
        }
    }

    // MARK: - Account Management

    func tapAddAccount() -> AccountFormScreen {
        XCTContext.runActivity(named: "Tap 'Add account' button") { _ in
            scrollToElement(addAccountButton)
            addAccountButton.waitAndTap()
            return AccountFormScreen(app)
        }
    }

    @discardableResult
    func verifyAddAccountButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Verify 'Add account' button is enabled") { _ in
            scrollToElement(addAccountButton)
            waitAndAssertTrue(addAccountButton, "Add account button should exist")
            XCTAssertTrue(addAccountButton.isEnabled, "Add account button should be enabled")
            return self
        }
    }

    @discardableResult
    func tapRenameWallet() -> WalletRenameAlert {
        XCTContext.runActivity(named: "Tap wallet rename row") { _ in
            waitAndAssertTrue(renameWalletRow, "Rename wallet row should be visible")
            renameWalletRow.waitAndTap()
            return WalletRenameAlert(app)
        }
    }

    @discardableResult
    func verifyWalletNameDisplayed(_ name: String) -> Self {
        XCTContext.runActivity(named: "Verify wallet name '\(name)' is displayed on Wallet Settings") { _ in
            let nameLabel = renameWalletRow.staticTexts[name]
            waitAndAssertTrue(nameLabel, "Wallet name '\(name)' should be visible inside rename row")
            return self
        }
    }

    private func anyElement(_ element: CardSettingsScreenElement) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: element.accessibilityIdentifier)
            .firstMatch
    }
}

enum CardSettingsScreenElement: String, UIElement {
    case referralButton
    case deviceSettings
    case addAccount
    case renameWalletRow

    var accessibilityIdentifier: String {
        switch self {
        case .referralButton:
            return CardSettingsAccessibilityIdentifiers.referralProgramButton
        case .deviceSettings:
            return CardSettingsAccessibilityIdentifiers.deviceSettingsButton
        case .addAccount:
            return AccountsAccessibilityIdentifiers.walletSettingsAddAccountButton
        case .renameWalletRow:
            return WalletSettingsAccessibilityIdentifiers.renameWalletRow
        }
    }
}
