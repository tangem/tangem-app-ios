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
    private static let historyScrollAttempts = 12
    private static let issuingCardTitle = "Issuing a new digital card"
    private static let issuingCardDescription = "Usually takes up to 5 minutes. In rare cases, up to 48 hours."
    private static let accountClosedTitle = "Your account has been closed"
    private static let removeAccountAlertTitle = "Remove account?"
    private static let removeAccountAlertButton = "Remove account"

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
    private lazy var toolbarTitle = staticText(.toolbarTitle)
    private lazy var toolbarSubtitle = staticText(.toolbarSubtitle)
    private lazy var addCardButton = button(.addCardButton)
    private lazy var emptyHistoryMessage = app.staticTexts
        .matching(NSPredicate(format: "label CONTAINS %@", "You don't have any transactions yet"))
        .firstMatch
    private lazy var balanceText = staticText(.paymentAccountBalance)
    private lazy var addFundsButton = button(.addFundsButton)
    private lazy var withdrawButton = button(.withdrawButton)
    private lazy var moreActionsButton = button(.moreActionsButton)
    private lazy var termsAndFeesMenuItem = button(.termsAndLimitsMenuItem)
    private lazy var removeAccountMenuItem = button(.removeAccountMenuItem)
    /// Type-agnostic: the banner is a plain container, not guaranteed to surface as a specific element type.
    private lazy var cardDeactivatedBanner = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.cardDeactivatedNotification].firstMatch
    /// The banner stamps its identifier onto the elements inside it, so its button carries the same one.
    private lazy var removeAccountBannerButton = notificationBannerButton(TangemPayAccessibilityIdentifiers.cardDeactivatedNotification)
    private lazy var backButton = app.navigationBars.buttons.element(boundBy: 0)
    private lazy var applePayGuideBanner = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.addToApplePayGuideBanner].firstMatch
    private lazy var applePayGuideBannerCloseButton = app.buttons[TangemPayAccessibilityIdentifiers.addToApplePayGuideBannerCloseButton].firstMatch
    /// Type-agnostic: the banner is a plain container, not guaranteed to surface as a specific element type.
    private lazy var issuingCardBanner = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.issuingCardBanner].firstMatch
    private lazy var issuingCardButton = button(.issuingCardButton)

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
    func tapAddCard() -> TangemPayIssueAdditionalCardSheet {
        XCTContext.runActivity(named: "Tap add card button to issue an additional card") { _ in
            addCardButton.waitAndTap()
            return TangemPayIssueAdditionalCardSheet(app)
        }
    }

    @discardableResult
    func tapIssuingCard() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap the card being issued to open its screen") { _ in
            issuingCardButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }

    @discardableResult
    func verifyIssuingCardBanner() -> Self {
        XCTContext.runActivity(named: "Verify 'Issuing a new digital card' banner is displayed") { _ in
            waitAndAssertTrue(issuingCardBanner, timeout: .networkRequest, "Issuing card banner should be displayed")
            waitAndAssertTrue(
                app.staticTexts[Self.issuingCardTitle].firstMatch,
                "Issuing card banner title should be displayed"
            )
            waitAndAssertTrue(
                app.staticTexts[Self.issuingCardDescription].firstMatch,
                "Issuing card banner description should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func waitForIssuingCardBannerHidden() -> Self {
        XCTContext.runActivity(named: "Wait for 'Issuing a new digital card' banner to disappear") { _ in
            XCTAssertTrue(
                issuingCardBanner.waitForNonExistence(timeout: .networkRequest),
                "Issuing card banner should disappear once the card is issued"
            )
            return self
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
    func verifyHeader(title expectedTitle: String, subtitle expectedSubtitle: String) -> Self {
        XCTContext.runActivity(named: "Verify header '\(expectedTitle)' and subtitle '\(expectedSubtitle)'") { _ in
            waitAndAssertTrue(toolbarTitle, "Payment account title should be displayed")
            XCTAssertEqual(toolbarTitle.label, expectedTitle, "Title should be '\(expectedTitle)'")

            waitAndAssertTrue(toolbarSubtitle, "Payment account subtitle should be displayed")
            XCTAssertEqual(toolbarSubtitle.label, expectedSubtitle, "Subtitle should be '\(expectedSubtitle)'")
            return self
        }
    }

    @discardableResult
    func verifyBalanceFormat() -> Self {
        XCTContext.runActivity(named: "Verify balance is a dollar amount with two decimals") { _ in
            waitAndAssertTrue(balanceText, timeout: .networkRequest, "Balance text should be displayed")
            XCTAssertTrue(
                balanceText.label.range(of: #"^\$\d[\d,]*\.\d{2}$"#, options: .regularExpression) != nil,
                "Balance should be formatted as $X.XX. Actual: '\(balanceText.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyActionButtonsVisible() -> Self {
        XCTContext.runActivity(named: "Verify Add funds and Withdraw buttons are displayed") { _ in
            waitAndAssertTrue(addFundsButton, "Add funds button should be displayed")
            waitAndAssertTrue(withdrawButton, "Withdraw button should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyCardsRowVisible() -> Self {
        XCTContext.runActivity(named: "Verify card and add card buttons are displayed") { _ in
            waitAndAssertTrue(paymentAccountCardButton, "Payment account card button should be displayed")
            waitAndAssertTrue(addCardButton, "Add card button should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyEmptyTransactionsState() -> Self {
        XCTContext.runActivity(named: "Verify empty transaction history state") { _ in
            waitAndAssertTrue(emptyHistoryMessage, timeout: .networkRequest, "Empty history message should be displayed")
            waitAndAssertTrue(historyStateIcon, "Empty history icon should be displayed")
            return self
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
    func tapWithdrawExpectingServiceUnavailable() -> TangemPayNoDepositAddressSheet {
        XCTContext.runActivity(named: "Tap Withdraw button expecting service unavailable sheet") { _ in
            withdrawButton.waitAndTap()
            return TangemPayNoDepositAddressSheet(app)
        }
    }

    @discardableResult
    func verifyAccountClosedBanner() -> Self {
        XCTContext.runActivity(named: "Verify account closed banner is displayed") { _ in
            waitAndAssertTrue(cardDeactivatedBanner, "Account closed banner should be displayed")
            // The banner may combine its texts into a single element, so any matching descendant is accepted.
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", Self.accountClosedTitle)
            waitAndAssertTrue(
                app.descendants(matching: .any).matching(predicate).firstMatch,
                "Banner should read '\(Self.accountClosedTitle)'"
            )
            return self
        }
    }

    @discardableResult
    func tapRemoveAccountOnBanner() -> Self {
        XCTContext.runActivity(named: "Tap Remove account on the account closed banner") { _ in
            removeAccountBannerButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func openRemoveAccountFromMoreActions() -> Self {
        XCTContext.runActivity(named: "Tap Remove account in more actions menu") { _ in
            moreActionsButton.waitAndTap()
            removeAccountMenuItem.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyRemoveAccountAlert() -> Self {
        XCTContext.runActivity(named: "Verify remove account confirmation alert") { _ in
            let alert = app.alerts[Self.removeAccountAlertTitle].firstMatch
            waitAndAssertTrue(alert, "Remove account confirmation alert should be displayed")
            waitAndAssertTrue(alert.buttons[Self.removeAccountAlertButton].firstMatch, "Alert should offer to remove the account")
            return self
        }
    }

    func confirmRemoveAccount() -> MainScreen {
        XCTContext.runActivity(named: "Confirm account removal") { _ in
            app.alerts[Self.removeAccountAlertTitle].buttons[Self.removeAccountAlertButton].firstMatch.waitAndTap()
            return MainScreen(app)
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
    func tapWithdraw() -> SwapScreen {
        XCTContext.runActivity(named: "Tap Withdraw button") { _ in
            withdrawButton.waitAndTap()
            return SwapScreen(app)
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
    func verifyCardDisabled() -> Self {
        XCTContext.runActivity(named: "Verify card is not tappable") { _ in
            waitAndAssertTrue(paymentAccountCardButton, "Payment account card button should be displayed")
            paymentAccountCardButton.waitForState(state: .disabled)
            return self
        }
    }

    @discardableResult
    func verifyStaleState(cachedBalance: String) -> Self {
        XCTContext.runActivity(named: "Verify Payment account is in stale state with cached balance '\(cachedBalance)'") { _ in
            verifyBalanceContains(cachedBalance)
            verifyWithdrawDisabled()
            verifyAddFundsDisabled()
            verifyCardDisabled()
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
            // Rows of the next page render only after the previous ones are scrolled past, so re-check after every swipe.
            for _ in 0 ..< Self.historyScrollAttempts where !row.exists {
                scrollToElement(row, attempts: .single)
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
    func verifyApplePayGuideBannerVisible() -> Self {
        XCTContext.runActivity(named: "Verify Apple/Google Pay banner is displayed on payment account") { _ in
            waitAndAssertTrue(
                applePayGuideBanner,
                timeout: .networkRequest,
                "Apple/Google Pay banner should be displayed on payment account screen"
            )
            return self
        }
    }

    @discardableResult
    func verifyApplePayGuideBannerHidden() -> Self {
        XCTContext.runActivity(named: "Verify Apple/Google Pay banner is not displayed on payment account") { _ in
            XCTAssertTrue(
                applePayGuideBanner.waitForNonExistence(timeout: .robustUIUpdate),
                "Apple/Google Pay banner should not be displayed on payment account screen"
            )
            return self
        }
    }

    @discardableResult
    func closeApplePayGuideBanner() -> Self {
        XCTContext.runActivity(named: "Close Apple/Google Pay banner") { _ in
            applePayGuideBannerCloseButton.waitAndTap()
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
    case toolbarTitle
    case toolbarSubtitle
    case addCardButton
    case issuingCardButton
    case addFundsButton
    case withdrawButton
    case moreActionsButton
    case termsAndLimitsMenuItem
    case removeAccountMenuItem

    var accessibilityIdentifier: String {
        switch self {
        case .paymentAccountBalance:
            TangemPayAccessibilityIdentifiers.paymentAccountBalance
        case .toolbarTitle:
            TangemPayAccessibilityIdentifiers.paymentAccountToolbarTitle
        case .toolbarSubtitle:
            TangemPayAccessibilityIdentifiers.paymentAccountToolbarSubtitle
        case .addCardButton:
            TangemPayAccessibilityIdentifiers.paymentAccountAddCardButton
        case .issuingCardButton:
            TangemPayAccessibilityIdentifiers.paymentAccountIssuingCardButton
        case .addFundsButton:
            TangemPayAccessibilityIdentifiers.addFundsButton
        case .withdrawButton:
            TangemPayAccessibilityIdentifiers.withdrawButton
        case .moreActionsButton:
            TangemPayAccessibilityIdentifiers.moreActionsButton
        case .termsAndLimitsMenuItem:
            TangemPayAccessibilityIdentifiers.termsAndLimitsMenuItem
        case .removeAccountMenuItem:
            TangemPayAccessibilityIdentifiers.removeAccountMenuItem
        }
    }
}
