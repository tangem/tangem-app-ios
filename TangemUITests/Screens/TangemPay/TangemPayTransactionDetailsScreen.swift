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

    private var date: XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.transactionDetailsDate].firstMatch
    }

    private var status: XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.transactionDetailsStatus].firstMatch
    }

    private var icon: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: TangemPayAccessibilityIdentifiers.transactionDetailsIcon)
            .firstMatch
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for transaction details screen") { _ in
            waitAndAssertTrue(title, "Transaction details title should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyHeader(title expectedTitle: String, dateContains expectedDate: String) -> Self {
        XCTContext.runActivity(named: "Verify header '\(expectedTitle)' and date containing '\(expectedDate)'") { _ in
            waitAndAssertTrue(title, "Transaction details title should be displayed")
            XCTAssertEqual(title.label, expectedTitle, "Details title should be '\(expectedTitle)'")

            waitAndAssertTrue(date, "Transaction details date should be displayed")
            XCTAssertTrue(
                date.label.contains(expectedDate),
                "Details date should contain '\(expectedDate)'. Actual: '\(date.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyAmount(_ expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Verify transaction amount '\(expectedAmount)'") { _ in
            waitAndAssertTrue(amount, "Transaction details amount should be displayed")
            XCTAssertEqual(amount.label, expectedAmount, "Details amount should be '\(expectedAmount)'")
            return self
        }
    }

    @discardableResult
    func verifyStatus(_ expectedStatus: String) -> Self {
        XCTContext.runActivity(named: "Verify transaction status '\(expectedStatus)'") { _ in
            waitAndAssertTrue(status, "Transaction status should be displayed")
            XCTAssertEqual(status.label, expectedStatus, "Transaction status should be '\(expectedStatus)'")
            return self
        }
    }

    @discardableResult
    func verifyIconVisible() -> Self {
        XCTContext.runActivity(named: "Verify transaction category icon is displayed") { _ in
            waitAndAssertTrue(icon, "Transaction details icon should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyGetHelpButton() -> Self {
        XCTContext.runActivity(named: "Verify Get Help button") { _ in
            waitAndAssertTrue(mainButton, "Get Help button should be displayed")
            XCTAssertEqual(mainButton.label, "Get Help", "Main button should be 'Get Help'. Actual: '\(mainButton.label)'")
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
