//
//  AddAccountWalletSelectorSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class AddAccountWalletSelectorSheet: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyWalletOptionDisplayed(_ walletName: String) -> Self {
        XCTContext.runActivity(named: "Verify wallet '\(walletName)' is offered in the wallet selector") { _ in
            waitAndAssertTrue(walletCell(walletName), "Wallet '\(walletName)' should be offered in the wallet selector")
            return self
        }
    }

    private func walletCell(_ walletName: String) -> XCUIElement {
        app.buttons[CommonUIAccessibilityIdentifiers.accountSelectorCell(name: walletName)].firstMatch
    }
}
