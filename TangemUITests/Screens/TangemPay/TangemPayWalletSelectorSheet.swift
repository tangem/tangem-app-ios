//
//  TangemPayWalletSelectorSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayWalletSelectorSheet: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[TangemPayAccessibilityIdentifiers.walletSelectorTitle].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay wallet selection sheet") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Wallet selection sheet title should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyWalletListed(_ walletName: String) -> Self {
        XCTContext.runActivity(named: "Verify wallet '\(walletName)' is listed in the wallet selection sheet") { _ in
            waitAndAssertTrue(
                app.buttons[walletName].firstMatch,
                "Wallet '\(walletName)' should be listed in the wallet selection sheet"
            )
            return self
        }
    }
}
