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
    /// Every Tangem Pay row shares this accessibility identifier key, see `TransactionViewModel.TransactionType`.
    private static let tangemPayKey = "tangemPay"
    private static let scrollRounds = 3

    private lazy var historyStateIcon = app.images[TxHistoryAccessibilityIdentifiers.statusStateIcon].firstMatch
    private lazy var historyErrorMessage = app.staticTexts
        .matching(NSPredicate(format: "label CONTAINS %@", "Failed to load transaction history"))
        .firstMatch
    private lazy var reloadHistoryButton = app.buttons
        .matching(NSPredicate(format: "label CONTAINS %@", "Reload"))
        .firstMatch
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
    func verifyWithdrawDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Withdraw button is disabled") { _ in
            waitAndAssertTrue(withdrawButton, "Withdraw button should be displayed")
            withdrawButton.waitForState(state: .disabled)
            return self
        }
    }

    @discardableResult
    func verifyAddFundsDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Add funds button is disabled") { _ in
            waitAndAssertTrue(addFundsButton, "Add funds button should be displayed")
            addFundsButton.waitForState(state: .disabled)
            return self
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
    func tapTransactionRow(containing text: String) -> TangemPayTransactionDetailsScreen {
        XCTContext.runActivity(named: "Tap transaction row containing '\(text)'") { _ in
            let row = app.buttons
                .containing(NSPredicate(format: "label CONTAINS %@", text))
                .firstMatch
            waitAndAssertTrue(row, "Transaction row containing '\(text)' should exist")
            row.tapEvenIfNotHittable()
            return TangemPayTransactionDetailsScreen(app)
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

    @discardableResult
    func verifyTransactionRow(name: String) -> Self {
        XCTContext.runActivity(named: "Verify transaction row '\(name)' is displayed") { _ in
            waitAndAssertTrue(
                transactionRowElement(identifier: TxHistoryAccessibilityIdentifiers.transactionItem(key: Self.tangemPayKey), label: name),
                timeout: .networkRequest,
                "Transaction row '\(name)' should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyTransactionRow(name: String, amount: String, category: String) -> Self {
        verifyTransactionRow(name: name)

        return XCTContext.runActivity(named: "Verify amount '\(amount)' and category '\(category)' of row '\(name)'") { _ in
            // All Tangem Pay rows share one identifier key, so amount and category are looked up inside this row only.
            let row = transactionRowContainer(name: name)
            waitAndAssertTrue(row, "Transaction row '\(name)' should exist")
            waitAndAssertTrue(
                rowText(in: row, identifier: TxHistoryAccessibilityIdentifiers.transactionAmount(key: Self.tangemPayKey), label: amount),
                "Transaction row '\(name)' should show amount '\(amount)'"
            )
            waitAndAssertTrue(
                rowText(in: row, identifier: TxHistoryAccessibilityIdentifiers.transactionSubtitle(key: Self.tangemPayKey), label: category),
                "Transaction row '\(name)' should show category '\(category)'"
            )
            return self
        }
    }

    @discardableResult
    func verifySectionHeader(_ header: String) -> Self {
        XCTContext.runActivity(named: "Verify transaction section header '\(header)'") { _ in
            waitAndAssertTrue(
                app.staticTexts[header].firstMatch,
                timeout: .networkRequest,
                "Transaction section header '\(header)' should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func scrollToTransaction(name: String) -> Self {
        XCTContext.runActivity(named: "Scroll the history down to transaction '\(name)'") { _ in
            let row = transactionRowElement(
                identifier: TxHistoryAccessibilityIdentifiers.transactionItem(key: Self.tangemPayKey),
                label: name
            )
            // Rows of the next page render only after the previous ones are scrolled past, so keep scrolling in rounds.
            for _ in 0 ..< Self.scrollRounds where !row.exists {
                scrollToElement(row, attempts: .lazy)
            }
            return self
        }
    }

    @discardableResult
    func tapTransaction(name: String) -> TangemPayTransactionDetailsScreen {
        scrollToTransaction(name: name)
        return tapTransactionRow(containing: name)
    }

    @discardableResult
    func verifyHistoryErrorState() -> Self {
        XCTContext.runActivity(named: "Verify transaction history error state") { _ in
            waitAndAssertTrue(historyErrorMessage, timeout: .networkRequest, "History error message should be displayed")
            waitAndAssertTrue(historyStateIcon, "History error icon should be displayed")
            waitAndAssertTrue(reloadHistoryButton, "Reload button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapReloadHistory() -> Self {
        XCTContext.runActivity(named: "Tap Reload in the transaction history error state") { _ in
            reloadHistoryButton.waitAndTap()
            return self
        }
    }

    private func transactionRowElement(identifier: String, label: String) -> XCUIElement {
        app.staticTexts
            .matching(identifier: identifier)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    private func transactionRowContainer(name: String) -> XCUIElement {
        app.buttons
            .containing(NSPredicate(format: "label CONTAINS %@", name))
            .firstMatch
    }

    private func rowText(in row: XCUIElement, identifier: String, label: String) -> XCUIElement {
        row.staticTexts
            .matching(identifier: identifier)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
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
