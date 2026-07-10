//
//  AddTokenFlowScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class AddTokenFlowScreen: Screen {
    let app: XCUIApplication

    private lazy var addTokenButton = app.buttons[TokenAccessibilityIdentifiers.addTokenButton].firstMatch
    private lazy var tokenAddedToast = app.staticTexts[CommonUIAccessibilityIdentifiers.successToast].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Add Token

    /// Selects a destination wallet in the "Choose wallet" sheet shown when multiple wallets can receive the token.
    @discardableResult
    func selectWallet(named walletName: String) -> Self {
        XCTContext.runActivity(named: "Select wallet '\(walletName)' to add the token to") { _ in
            let walletCell = app.descendants(matching: .any)[CommonUIAccessibilityIdentifiers.accountSelectorCell(name: walletName)].firstMatch
            if walletCell.waitForExistence(timeout: .robustUIUpdate) {
                walletCell.waitAndTap()
                return
            }
            let walletButton = app.buttons.matching(NSPredicate(format: "label == %@", walletName)).firstMatch
            waitAndAssertTrue(walletButton, "Wallet '\(walletName)' should be selectable in the Choose wallet sheet")
            walletButton.waitAndTap()
        }
        return self
    }

    /// Taps the "Add Token" button to trigger token addition
    @discardableResult
    func tapAddTokenButton() -> Self {
        _ = XCTContext.runActivity(named: "Tap 'Add Token' button") { _ in
            addTokenButton.waitAndTap()
        }
        return self
    }

    // MARK: - Toast Verification

    @discardableResult
    func waitForTokenAddedToastOnAddFundsScreen() -> AddFundsScreen {
        XCTContext.runActivity(named: "Wait for 'Token Added' toast on Add Funds screen") { _ in
            waitAndAssertTrue(tokenAddedToast, timeout: .conditional, "Wait for 'Token Added' toast is displayed")
            return AddFundsScreen(app)
        }
    }

    @discardableResult
    func waitForTokenAddedToastOnMarketsTokenDetails() -> MarketsTokenDetailsScreen {
        XCTContext.runActivity(named: "Wait for 'Token Added' toast on Markets token details screen") { _ in
            waitAndAssertTrue(tokenAddedToast, timeout: .conditional, "Wait for 'Token Added' toast is displayed")
            return MarketsTokenDetailsScreen(app)
        }
    }

    /// Waits for the "Token added" toast notification and returns to the swap screen
    @discardableResult
    func waitForTokenAddedToast() -> SwapScreen {
        XCTContext.runActivity(named: "Wait for 'Token added' toast and transition back to swap screen") { _ in
            let swapTitle = app.scrollViews[SwapAccessibilityIdentifiers.title]
            XCTAssertTrue(
                swapTitle.waitForExistence(timeout: .robustUIUpdate),
                "Swap screen should appear after token is added"
            )
            return SwapScreen(app)
        }
    }
}
