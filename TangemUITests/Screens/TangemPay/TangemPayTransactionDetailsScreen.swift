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

    private var amountSubtitle: XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.transactionDetailsAmountSubtitle].firstMatch
    }

    private var statusReason: XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.transactionDetailsStatusReason].firstMatch
    }

    private var statusIcon: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: TangemPayAccessibilityIdentifiers.transactionDetailsStatusIcon)
            .firstMatch
    }

    /// The retry control keeps its own identifier when the row exposes it, otherwise the row itself carries the error text.
    private var cardRowLoadingError: XCUIElement {
        let predicate = NSPredicate(
            format: "identifier == %@ OR (identifier == %@ AND label CONTAINS[c] %@)",
            TangemPayAccessibilityIdentifiers.transactionDetailsCardRowRetryButton,
            TangemPayAccessibilityIdentifiers.transactionDetailsCardRow,
            Localization.tangempayCommonErrorLoading
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    private var cardRowRetryButton: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: TangemPayAccessibilityIdentifiers.transactionDetailsCardRowRetryButton)
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

    /// The subtitle under the amount carries the merchant name, prefixed with the foreign amount for cross-currency transactions.
    @discardableResult
    func verifyMerchantName(_ expectedName: String) -> Self {
        XCTContext.runActivity(named: "Verify merchant name '\(expectedName)'") { _ in
            waitAndAssertTrue(amountSubtitle, "Amount subtitle should be displayed")
            XCTAssertTrue(
                amountSubtitle.label.contains(expectedName),
                "Amount subtitle should contain '\(expectedName)'. Actual: '\(amountSubtitle.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyCategory(_ expectedCategory: String) -> Self {
        XCTContext.runActivity(named: "Verify transaction category '\(expectedCategory)'") { _ in
            waitAndAssertTrue(
                row(TangemPayAccessibilityIdentifiers.transactionDetailsCategoryRow, containing: expectedCategory),
                "Category row should show '\(expectedCategory)'"
            )
            return self
        }
    }

    /// The card row is filled by a separate transaction request, so the masked number is awaited instead of read right away.
    @discardableResult
    func verifyCard(numberEnd: String, cardName: String) -> Self {
        XCTContext.runActivity(named: "Verify card row shows '*\(numberEnd)' and '\(cardName)'") { _ in
            let maskedNumber = "*" + numberEnd
            let cardRow = row(TangemPayAccessibilityIdentifiers.transactionDetailsCardRow, containing: maskedNumber)
            waitAndAssertTrue(cardRow, timeout: .networkRequest, "Card row should show the masked number '\(maskedNumber)'")

            let label = cardRow.label
            XCTAssertTrue(label.contains(cardName), "Card row should show the card name '\(cardName)'. Actual: '\(label)'")
            return self
        }
    }

    @discardableResult
    func verifyStatusReason(_ expectedReason: String) -> Self {
        XCTContext.runActivity(named: "Verify status reason '\(expectedReason)'") { _ in
            waitAndAssertTrue(statusReason, "Transaction status reason should be displayed")
            XCTAssertEqual(
                statusReason.label,
                expectedReason,
                "Status reason should be '\(expectedReason)'. Actual: '\(statusReason.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyStatusIconVisible() -> Self {
        XCTContext.runActivity(named: "Verify transaction status icon is displayed") { _ in
            waitAndAssertTrue(statusIcon, "Transaction status icon should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyCardRowLoadingError() -> Self {
        XCTContext.runActivity(named: "Verify card row shows the loading error") { _ in
            waitAndAssertTrue(
                cardRowLoadingError,
                timeout: .networkRequest,
                "Card row should show the '\(Localization.tangempayCommonErrorLoading)' state"
            )
            return self
        }
    }

    @discardableResult
    func tapCardRowRetry() -> Self {
        XCTContext.runActivity(named: "Tap retry in the card row error state") { _ in
            waitAndAssertTrue(cardRowLoadingError, "Card row retry control should be displayed")
            let retryControl = cardRowRetryButton.exists ? cardRowRetryButton : cardRowLoadingError
            retryControl.tapEvenIfNotHittable()
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
            XCTAssertEqual(mainButton.label, Localization.tangemPayGetHelp, "Main button should be 'Get Help'. Actual: '\(mainButton.label)'")
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

            verifyCategory(category)
            waitAndAssertTrue(mainButton, "Transaction details main button should be displayed")
            return self
        }
    }

    /// Rows combine their texts into a single accessibility element, so a row is located by its identifier and combined label.
    private func row(_ identifier: String, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, text))
            .firstMatch
    }
}
