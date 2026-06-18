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

    /// Taps the "Add Token" button to trigger token addition
    @discardableResult
    func tapAddTokenButton() -> Self {
        XCTContext.runActivity(named: "Tap 'Add Token' button") { _ in
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
