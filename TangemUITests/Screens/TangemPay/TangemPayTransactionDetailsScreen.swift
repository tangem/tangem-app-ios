//
//  TangemPayTransactionDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayTransactionDetailsScreen: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    private var title: XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.transactionDetailsTitle].firstMatch
    }

    private var amount: XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.transactionDetailsAmount].firstMatch
    }

    private var mainButton: XCUIElement {
        app.buttons[TangemPayAccessibilityIdentifiers.transactionDetailsMainButton].firstMatch
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for transaction details screen") { _ in
            waitAndAssertTrue(title, "Transaction details title should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyFeeDetails(title expectedTitle: String, amount expectedAmount: String, category: String) -> Self {
        XCTContext.runActivity(named: "Verify fee transaction details") { _ in
            waitAndAssertTrue(title, "Transaction details title should be displayed")
            XCTAssertEqual(title.label, expectedTitle, "Details title should be '\(expectedTitle)'")

            waitAndAssertTrue(amount, "Transaction details amount should be displayed")
            XCTAssertEqual(amount.label, expectedAmount, "Details amount should be '\(expectedAmount)'")

            waitAndAssertTrue(app.staticTexts[category].firstMatch, "Category '\(category)' should be displayed")
            waitAndAssertTrue(mainButton, "Transaction details main button should be displayed")
            return self
        }
    }
}
