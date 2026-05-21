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
    private lazy var paymentAccountCardButton = button(.paymentAccountCardButton)
    private lazy var balanceText = staticText(.paymentAccountBalance)
    private lazy var addFundsButton = button(.addFundsButton)
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
    case paymentAccountCardButton
    case paymentAccountBalance
    case addFundsButton

    var accessibilityIdentifier: String {
        switch self {
        case .paymentAccountCardButton:
            TangemPayAccessibilityIdentifiers.paymentAccountCardButton
        case .paymentAccountBalance:
            TangemPayAccessibilityIdentifiers.paymentAccountBalance
        case .addFundsButton:
            TangemPayAccessibilityIdentifiers.addFundsButton
        }
    }
}
