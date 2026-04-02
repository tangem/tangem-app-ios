//
//  ArchivedAccountsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class ArchivedAccountsScreen: ScreenBase<ArchivedAccountsScreenElement> {
    @discardableResult
    func verifyArchivedAccountExists(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Verify archived account '\(accountName)' exists") { _ in
            let recoverButton = app.buttons[AccountsAccessibilityIdentifiers.archivedAccountRecoverButton(accountName: accountName)]
            waitAndAssertTrue(recoverButton, "Archived account '\(accountName)' should be visible")
            return self
        }
    }

    @discardableResult
    func verifyArchivedAccountNotExists(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Verify archived account '\(accountName)' does not exist") { _ in
            let recoverButton = app.buttons[AccountsAccessibilityIdentifiers.archivedAccountRecoverButton(accountName: accountName)]
            XCTAssertFalse(
                recoverButton.waitForExistence(timeout: .conditional),
                "Archived account '\(accountName)' should not be visible"
            )
            return self
        }
    }

    func tapRecoverButton(for accountName: String) -> CardSettingsScreen {
        XCTContext.runActivity(named: "Tap recover button for '\(accountName)'") { _ in
            let recoverButton = app.buttons[AccountsAccessibilityIdentifiers.archivedAccountRecoverButton(accountName: accountName)]
            recoverButton.waitAndTap()
            return CardSettingsScreen(app)
        }
    }

    @discardableResult
    func tapRecoverButtonExpectingError(for accountName: String) -> Self {
        XCTContext.runActivity(named: "Tap recover button for '\(accountName)' (expecting error)") { _ in
            let recoverButton = app.buttons[AccountsAccessibilityIdentifiers.archivedAccountRecoverButton(accountName: accountName)]
            recoverButton.waitAndTap()
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

    @discardableResult
    func verifyArchivedAccountTokenInfo(_ accountName: String, expectedInfo: String) -> Self {
        XCTContext.runActivity(named: "Verify token info for archived account '\(accountName)' contains '\(expectedInfo)'") { _ in
            let tokenInfo = app.staticTexts[AccountsAccessibilityIdentifiers.archivedAccountTokenInfo(accountName: accountName)]
            waitAndAssertTrue(tokenInfo, "Token info should be visible for archived account '\(accountName)'")
            XCTAssertTrue(
                tokenInfo.label.contains(expectedInfo),
                "Expected '\(expectedInfo)' in '\(tokenInfo.label)'"
            )
            return self
        }
    }

    func goBackToWalletSettings() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Go back to Wallet settings") { _ in
            app.navigationBars.buttons["Wallet settings"].waitAndTap()
            return CardSettingsScreen(app)
        }
    }
}

enum ArchivedAccountsScreenElement: String, UIElement {
    case placeholder

    var accessibilityIdentifier: String {
        switch self {
        case .placeholder:
            return ""
        }
    }
}
