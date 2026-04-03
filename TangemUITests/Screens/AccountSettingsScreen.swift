//
//  AccountSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest
import TangemAccessibilityIdentifiers

final class AccountSettingsScreen: ScreenBase<AccountSettingsScreenElement> {
    private lazy var manageTokensButton = button(.manageTokenButton)
    private lazy var archiveButton = button(.archiveButton)

    func openManageTokens() -> ManageTokensScreen {
        XCTContext.runActivity(named: "Open Manage tokens (Account Settings)") { _ in
            manageTokensButton.waitAndTap()
            return ManageTokensScreen(app)
        }
    }

    func goBackToWalletSettings() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Go back to Wallet settings") { _ in
            app.navigationBars.buttons["Wallet settings"].waitAndTap()
            return CardSettingsScreen(app)
        }
    }

    @discardableResult
    func verifyArchiveButtonVisible() -> Self {
        XCTContext.runActivity(named: "Verify archive button is visible") { _ in
            waitAndAssertTrue(archiveButton, "Archive button should be visible")
            return self
        }
    }

    @discardableResult
    func verifyArchiveButtonNotVisible() -> Self {
        XCTContext.runActivity(named: "Verify archive button is not visible") { _ in
            XCTAssertFalse(
                archiveButton.waitForExistence(timeout: .conditional),
                "Archive button should not be visible for main account"
            )
            return self
        }
    }

    @discardableResult
    func tapArchiveButton() -> Self {
        XCTContext.runActivity(named: "Tap archive button") { _ in
            archiveButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyArchiveDialogVisible() -> Self {
        XCTContext.runActivity(named: "Verify archive confirmation dialog is visible") { _ in
            let dialog = app.popovers.firstMatch
            waitAndAssertTrue(dialog, "Archive confirmation dialog should be visible")
            let archiveAction = dialog.buttons["Archive account"]
            waitAndAssertTrue(archiveAction, "Archive action button should be visible in dialog")
            return self
        }
    }

    func confirmArchiveDialog() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Confirm archive in dialog") { _ in
            let archiveAction = app.popovers.firstMatch.buttons["Archive account"]
            archiveAction.waitAndTap()
            return CardSettingsScreen(app)
        }
    }

    @discardableResult
    func confirmArchiveDialogExpectingError() -> Self {
        XCTContext.runActivity(named: "Confirm archive in dialog (expecting error)") { _ in
            let archiveAction = app.popovers.firstMatch.buttons["Archive account"]
            archiveAction.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyErrorAlert(expectedMessage: String) -> Self {
        XCTContext.runActivity(named: "Verify error alert with message: '\(expectedMessage)'") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Error alert should be displayed")

            let messageText = alert.staticTexts.element(
                matching: NSPredicate(format: "label CONTAINS[c] %@", expectedMessage)
            ).firstMatch
            XCTAssertTrue(messageText.exists, "Alert should contain message '\(expectedMessage)'")

            return self
        }
    }

    @discardableResult
    func dismissErrorAlert(buttonTitle: String = "OK") -> Self {
        XCTContext.runActivity(named: "Dismiss error alert") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Error alert should be displayed")
            alert.buttons[buttonTitle].waitAndTap()
            return self
        }
    }
}

enum AccountSettingsScreenElement: String, UIElement {
    case manageTokenButton
    case archiveButton

    var accessibilityIdentifier: String {
        switch self {
        case .manageTokenButton:
            return AccountsAccessibilityIdentifiers.accountDetailsManageTokensButton
        case .archiveButton:
            return AccountsAccessibilityIdentifiers.accountDetailsArchiveButton
        }
    }
}
