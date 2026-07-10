//
//  TangemPayMainScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayMainScreen: ScreenBase<TangemPayMainScreenElement> {
    private lazy var paymentAccountCardButton = app.buttons
        .matching(NSPredicate(format: "identifier BEGINSWITH %@", TangemPayAccessibilityIdentifiers.paymentAccountCardButtonPrefix))
        .firstMatch
    private lazy var balanceText = staticText(.paymentAccountBalance)
    private lazy var addFundsButton = button(.addFundsButton)
    private lazy var withdrawButton = button(.withdrawButton)
    private lazy var moreActionsButton = button(.moreActionsButton)
    private lazy var termsAndFeesMenuItem = button("Terms and fees")
    private lazy var backButton = app.navigationBars.buttons.element(boundBy: 0)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay payment account screen") { _ in
            waitAndAssertTrue(paymentAccountCardButton, "Payment account card button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapCard() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap card icon to open card management") { _ in
            paymentAccountCardButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }

    @discardableResult
    func waitForBalanceLoaded() -> Self {
        XCTContext.runActivity(named: "Wait for balance to load") { _ in
            waitAndAssertTrue(balanceText, timeout: .networkRequest, "Balance text should be displayed")
            return self
        }
    }

    func readBalance() -> String {
        XCTContext.runActivity(named: "Read current balance") { _ in
            waitAndAssertTrue(balanceText, timeout: .networkRequest, "Balance text should be displayed")
            return balanceText.label
        }
    }

    @discardableResult
    func verifyBalanceContains(_ expectedSubstring: String) -> Self {
        XCTContext.runActivity(named: "Verify balance contains '\(expectedSubstring)'") { _ in
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", expectedSubstring)
            let match = app.staticTexts
                .matching(identifier: TangemPayAccessibilityIdentifiers.paymentAccountBalance)
                .matching(predicate)
                .firstMatch
            XCTAssertTrue(
                match.waitForExistence(timeout: .networkRequest),
                "Balance should contain '\(expectedSubstring)'. Actual: '\(balanceText.label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapBack() -> MainScreen {
        XCTContext.runActivity(named: "Tap back to return to main screen") { _ in
            backButton.waitAndTap()
            return MainScreen(app)
        }
    }

    @discardableResult
    func tapAddFunds() -> TangemPayAddFundsSheet {
        XCTContext.runActivity(named: "Tap Add funds button") { _ in
            addFundsButton.waitAndTap()
            return TangemPayAddFundsSheet(app)
        }
    }

    @discardableResult
    func tapAddFundsExpectingServiceUnavailable() -> TangemPayNoDepositAddressSheet {
        XCTContext.runActivity(named: "Tap Add funds button expecting service unavailable sheet") { _ in
            addFundsButton.waitAndTap()
            return TangemPayNoDepositAddressSheet(app)
        }
    }

    @discardableResult
    func openTermsAndFees() -> TangemPayTermsAndFeesSheet {
        XCTContext.runActivity(named: "Open Terms and fees from more actions menu") { _ in
            moreActionsButton.waitAndTap()
            termsAndFeesMenuItem.waitAndTap()
            return TangemPayTermsAndFeesSheet(app)
        }
    }

    @discardableResult
    func tapWithdraw() -> TangemPayWithdrawNoteSheet {
        XCTContext.runActivity(named: "Tap Withdraw button") { _ in
            withdrawButton.waitAndTap()
            return TangemPayWithdrawNoteSheet(app)
        }
    }

    @discardableResult
    func verifyPendingExpressTransactionVisible() -> Self {
        XCTContext.runActivity(named: "Verify pending express transaction row is visible") { _ in
            let row = app.buttons[TokenAccessibilityIdentifiers.pendingExpressTransaction].firstMatch
            XCTAssertTrue(
                row.waitForExistence(timeout: .networkRequest),
                "Pending express transaction row should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyTransactionRowVisible(label: String) -> Self {
        XCTContext.runActivity(named: "Verify transaction row '\(label)' is visible") { _ in
            let txCell = app.staticTexts[label].firstMatch
            XCTAssertTrue(
                txCell.waitForExistence(timeout: .networkRequest),
                "Transaction row '\(label)' should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyTransactionVisible(merchantName: String) -> Self {
        XCTContext.runActivity(named: "Verify transaction with merchant '\(merchantName)' is visible") { _ in
            let txCell = app.staticTexts[merchantName].firstMatch
            XCTAssertTrue(
                txCell.waitForExistence(timeout: .networkRequest),
                "Transaction with merchant '\(merchantName)' should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyTransactionNotVisible(merchantName: String) -> Self {
        XCTContext.runActivity(named: "Verify transaction with merchant '\(merchantName)' is NOT visible") { _ in
            let txCell = app.staticTexts[merchantName].firstMatch
            XCTAssertFalse(
                txCell.waitForExistence(timeout: .conditional),
                "Transaction with merchant '\(merchantName)' should NOT be displayed yet"
            )
            return self
        }
    }
}

enum TangemPayMainScreenElement: String, UIElement {
    case paymentAccountBalance
    case addFundsButton
    case withdrawButton
    case moreActionsButton

    var accessibilityIdentifier: String {
        switch self {
        case .paymentAccountBalance:
            TangemPayAccessibilityIdentifiers.paymentAccountBalance
        case .addFundsButton:
            TangemPayAccessibilityIdentifiers.addFundsButton
        case .withdrawButton:
            TangemPayAccessibilityIdentifiers.withdrawButton
        case .moreActionsButton:
            TangemPayAccessibilityIdentifiers.moreActionsButton
        }
    }
}
