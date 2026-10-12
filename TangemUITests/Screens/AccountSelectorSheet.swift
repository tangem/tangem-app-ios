//
//  AccountSelectorSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class AccountSelectorSheet: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyAccountVisible(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Verify account '\(accountName)' is offered in the account selector") { _ in
            waitAndAssertTrue(
                accountRow(accountName),
                "Account '\(accountName)' should be offered in the account selector"
            )
            return self
        }
    }

    @discardableResult
    func verifyAccountNotVisible(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Verify account '\(accountName)' is NOT offered in the account selector") { _ in
            XCTAssertFalse(
                accountRow(accountName).waitForExistence(timeout: .conditional),
                "Account '\(accountName)' should NOT be offered in the account selector"
            )
            return self
        }
    }

    private func accountRow(_ accountName: String) -> XCUIElement {
        app.buttons[AccountsAccessibilityIdentifiers.walletSettingsAccountRow(accountName: accountName)].firstMatch
    }
}
