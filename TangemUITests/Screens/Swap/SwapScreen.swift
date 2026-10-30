//
//  SwapScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SwapScreen: ScreenBase<SwapScreenElement> {
    private lazy var titleLabel = scrollView(.title)
    private lazy var fromAmountTextField = textField(.fromAmountTextField)
    private lazy var toAmountTextField = otherElement(.toAmountTextField)
    private lazy var receiveAmountValue = app.staticTexts[SwapAccessibilityIdentifiers.receiveAmountValue].firstMatch
    private lazy var feeBlock = button(.feeBlock)
    private lazy var normalFeeOption = button(.normalFeeOption)
    private lazy var priorityFeeOption = button(.priorityFeeOption)
    private lazy var swapTokensButton = button(.swapTokensButton)
    private lazy var confirmButton = button(.confirmButton)
    private lazy var chooseSpeedTitle = app.staticTexts[FeeAccessibilityIdentifiers.feeSelectorChooseSpeedTitle]
    private lazy var closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch
    private lazy var fromTokenSelector = app.buttons.matching(
        NSPredicate(format: "identifier == %@ AND label CONTAINS %@", SwapAccessibilityIdentifiers.fromAmountTextField, "chevronDownMini")
    ).firstMatch
    private lazy var receiveTokenSelector = app.buttons[SwapAccessibilityIdentifiers.tokenSelector].firstMatch
    private lazy var priceChangeInfoButton = app.buttons[SwapAccessibilityIdentifiers.priceChangeInfoButton].firstMatch

    private lazy var swapContainer = app.scrollViews[SwapAccessibilityIdentifiers.title]
    /// Every banner stamps the same identifier, so a single element would resolve ambiguously once two are shown.
    private lazy var notificationTitles = swapContainer.staticTexts.matching(identifier: CommonUIAccessibilityIdentifiers.notificationTitle)
    private lazy var notificationMessages = swapContainer.staticTexts.matching(identifier: CommonUIAccessibilityIdentifiers.notificationMessage)
    private lazy var notificationIcon = swapContainer.images[CommonUIAccessibilityIdentifiers.notificationIcon].firstMatch
    private lazy var insufficientFundsText = swapContainer.staticTexts["Insufficient funds"].firstMatch

    @discardableResult
    func validateSwapScreenDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Swap screen is displayed") { _ in
            XCTAssertTrue(titleLabel.waitForExistence(timeout: .robustUIUpdate), "Swap screen title should exist")
            XCTAssertTrue(fromAmountTextField.waitForExistence(timeout: .robustUIUpdate), "From amount text field should exist")
            XCTAssertTrue(toAmountTextField.waitForExistence(timeout: .robustUIUpdate), "To amount text field should exist")
        }
        return self
    }

    @discardableResult
    func enterFromAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Enter amount '\(amount)' in from field") { _ in
            // The field formats the value with grouping separators, so compare on digits and the decimal separator only.
            let expectedDigits = amount.filter { $0.isNumber || $0 == "." }
            let field = editableFromAmountField()
            waitForFieldEnabled(field)

            // [REDACTED_INFO]: the field resigns focus on swap-state re-renders, so clear, refocus and retype until it sticks.
            for _ in 0 ..< 8 {
                guard focusFromAmountFieldStably(field) else {
                    continue
                }
                let length = enteredFromAmountLength(field)
                if length > 0 {
                    field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: length))
                }
                // A swap-state re-render can resign focus between clearing and typing; refocus so typeText won't throw.
                guard fromAmountFieldHasKeyboardFocus() || focusFromAmountFieldStably(field) else {
                    continue
                }
                field.typeText(amount)
                if field.waitForValue(timeout: .quick, where: { $0.filter { $0.isNumber || $0 == "." } == expectedDigits }) {
                    return
                }
            }
            XCTFail("Failed to enter amount '\(amount)'; last value: '\(field.getValue())'")
        }
        return self
    }

    @discardableResult
    func waitForFeeCalculation() -> Self {
        XCTContext.runActivity(named: "Wait for fee calculation to complete") { _ in
            XCTAssertTrue(feeBlock.waitForExistence(timeout: .robustUIUpdate), "Fee block should appear after calculation")
        }
        return self
    }

    @discardableResult
    func validateReceivedAmount() -> Self {
        XCTContext.runActivity(named: "Validate 'You receive' amount is greater than zero") { _ in
            waitAndAssertTrue(toAmountTextField, "Receive section container should exist")
            let toAmountElements = toAmountTextField.staticTexts
            XCTAssertTrue(toAmountElements.firstMatch.waitForExistence(timeout: .robustUIUpdate), "To amount elements should exist")

            var youReceiveText = ""
            let elementsCount = toAmountElements.count

            for index in 0 ..< elementsCount {
                let element = toAmountElements.element(boundBy: index)
                if element.exists {
                    let elementText = element.label
                    if elementText.hasPrefix("~") {
                        youReceiveText = elementText
                        break
                    }
                }
            }

            XCTAssertFalse(youReceiveText.isEmpty, "You receive amount should not be empty")

            let cleanedText = youReceiveText.replacingOccurrences(of: "~", with: "").trimmingCharacters(in: .whitespaces)
            var numericString = cleanedText.replacingOccurrences(of: ",", with: ".")

            if let range = numericString.range(of: "[0-9]+(\\.[0-9]+)?", options: .regularExpression) {
                numericString = String(numericString[range])
            } else {
                XCTFail("No valid numeric pattern found in 'You receive' text: '\(youReceiveText)'")
                return
            }

            guard let numericValue = Double(numericString) else {
                XCTFail("Failed to parse numeric value from 'You receive' text: '\(youReceiveText)'. Extracted string: '\(numericString)'")
                return
            }

            XCTAssertTrue(numericValue > 0, "You receive amount should be greater than zero. Actual value: \(numericValue)")
        }
        return self
    }

    @discardableResult
    func tapFeeBlock() -> Self {
        XCTContext.runActivity(named: "Tap fee block to open fee selector") { _ in
            XCTAssertTrue(feeBlock.waitForExistence(timeout: .robustUIUpdate), "Fee block should exist")
            feeBlock.tap()
        }
        return self
    }

    @discardableResult
    func waitForFeeSelectorToAppear() -> Self {
        XCTContext.runActivity(named: "Wait for fee selector to appear") { _ in
            XCTAssertTrue(chooseSpeedTitle.waitForExistence(timeout: .robustUIUpdate), "Fee selector title 'Choose speed' should appear")
            XCTAssertTrue(normalFeeOption.waitForExistence(timeout: .robustUIUpdate), "Normal/Market fee option should exist")
            XCTAssertTrue(priorityFeeOption.waitForExistence(timeout: .robustUIUpdate), "Priority/Fast fee option should exist")
        }
        return self
    }

    @discardableResult
    func assertFeeOptionsHaveDifferentFees() -> Self {
        XCTContext.runActivity(named: "Assert Market and Fast fee options show different fee amounts") { _ in
            XCTAssertTrue(normalFeeOption.waitForExistence(timeout: .robustUIUpdate), "Normal/Market fee option should exist")
            XCTAssertTrue(priorityFeeOption.waitForExistence(timeout: .robustUIUpdate), "Priority/Fast fee option should exist")
            // The rounded fiat summary can be identical for both options; the open row label carries the crypto amount too.
            XCTAssertNotEqual(
                normalFeeOption.label,
                priorityFeeOption.label,
                "Market and Fast fee options should show different fee amounts"
            )
        }
        return self
    }

    @discardableResult
    func selectFeeOption(_ option: FeeOptionType) -> Self {
        XCTContext.runActivity(named: "Select \(option.rawValue) fee option") { _ in
            let targetButton = option == .normal ? normalFeeOption : priorityFeeOption
            XCTAssertTrue(targetButton.waitForExistence(timeout: .robustUIUpdate), "\(option.rawValue) fee option should exist")
            targetButton.tap()
        }
        return self
    }

    @discardableResult
    func waitForFeeOptionSelected(_ option: FeeOptionType) -> Self {
        XCTContext.runActivity(named: "Validate \(option.rawValue) fee option is selected") { _ in
            let targetButton = option == .normal ? normalFeeOption : priorityFeeOption
            let indicator = targetButton.descendants(matching: .any)[FeeAccessibilityIdentifiers.feeOptionSelectedIndicator]
            waitAndAssertTrue(indicator, "\(option.rawValue) fee option should be selected")
        }
        return self
    }

    @discardableResult
    func waitForFeeOptionNotSelected(_ option: FeeOptionType) -> Self {
        XCTContext.runActivity(named: "Validate \(option.rawValue) fee option is not selected") { _ in
            let targetButton = option == .normal ? normalFeeOption : priorityFeeOption
            let indicator = targetButton.descendants(matching: .any)[FeeAccessibilityIdentifiers.feeOptionSelectedIndicator]
            XCTAssertTrue(indicator.waitForNonExistence(timeout: .robustUIUpdate), "\(option.rawValue) fee option should not be selected")
        }
        return self
    }

    @discardableResult
    func validateFeeChanged() -> Self {
        XCTContext.runActivity(named: "Validate fee has changed after option selection") { _ in
            XCTAssertTrue(chooseSpeedTitle.waitForNonExistence(timeout: .robustUIUpdate), "Fee selector should disappear after selection")
            XCTAssertTrue(feeBlock.waitForExistence(timeout: .robustUIUpdate), "Fee block should still exist after fee change")
        }
        return self
    }

    @discardableResult
    func waitErrorShown(title: String? = nil, message: String? = nil) -> Self {
        XCTContext.runActivity(named: "Wait for error banner") { _ in
            // The error banner is shown over the screen rather than inside the swap container, so it is looked up on the app.
            switch (title, message) {
            case (.some(let title), .some(let message)):
                let banner = app.descendants(matching: .any)
                    .matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", title, message))
                    .firstMatch
                waitAndAssertTrue(banner, "Error banner '\(title)' with message '\(message)' should be shown")

            case (.some(let title), .none):
                waitAndAssertTrue(errorLabel(identifier: CommonUIAccessibilityIdentifiers.notificationTitle, text: title), "Error banner '\(title)' should be shown")

            case (.none, .some(let message)):
                waitAndAssertTrue(errorLabel(identifier: CommonUIAccessibilityIdentifiers.notificationMessage, text: message), "Error message '\(message)' should be shown")

            case (.none, .none):
                break
            }
        }
        return self
    }

    @discardableResult
    func waitFromTokenDisplayed(tokenSymbol: String) -> Self {
        XCTContext.runActivity(named: "Validate 'You swap' section displays token '\(tokenSymbol)' with icon") { _ in
            let fromContainerQuery = app.descendants(matching: .staticText).matching(identifier: SwapAccessibilityIdentifiers.fromAmountTextField)
            let symbolPredicate = NSPredicate(format: "label == %@", tokenSymbol)
            let symbolElement = fromContainerQuery.element(matching: symbolPredicate)
            XCTAssertTrue(symbolElement.waitForExistence(timeout: .robustUIUpdate), "Token symbol '\(tokenSymbol)' should be displayed in 'You swap' section")
        }
        return self
    }

    /// Selects a receive token from the inline token list shown on the swap screen
    @discardableResult
    func selectReceiveToken(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Select receive token '\(tokenName)' from inline token list") { _ in
            let tokenButton = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: tokenName)].firstMatch
            waitAndAssertTrue(tokenButton, "Token '\(tokenName)' should be visible in receive token list")
            tokenButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapSwapTokensButton() -> Self {
        XCTContext.runActivity(named: "Tap swap tokens (reverse) button") { _ in
            waitAndAssertTrue(swapTokensButton, "Swap tokens button should exist")
            swapTokensButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapToTokenSelector() -> SwapTokenSelectorScreen {
        XCTContext.runActivity(named: "Tap receive token selector") { _ in
            waitAndAssertTrue(receiveTokenSelector, "Receive token selector button should exist")
            receiveTokenSelector.waitAndTap()

            return SwapTokenSelectorScreen(app)
        }
    }

    @discardableResult
    func tapFromTokenSelector() -> SwapTokenSelectorScreen {
        XCTContext.runActivity(named: "Tap from token selector") { _ in
            waitAndAssertTrue(fromTokenSelector, "From token selector button should exist")
            fromTokenSelector.waitAndTap()

            return SwapTokenSelectorScreen(app)
        }
    }

    @discardableResult
    func chooseReceiveToken(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Choose receive token '\(tokenName)' via TO selector") { _ in
            waitAndAssertTrue(receiveTokenSelector, "Receive token selector button should exist")
            receiveTokenSelector.waitAndTap()

            let tokenButton = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: tokenName)].firstMatch
            waitAndAssertTrue(tokenButton, "Token '\(tokenName)' should be visible in receive token selector")
            tokenButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func chooseSourceToken(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Choose source token '\(tokenName)' via FROM selector") { _ in
            waitAndAssertTrue(fromTokenSelector, "From token selector button should exist")
            fromTokenSelector.waitAndTap()

            let tokenButton = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: tokenName)].firstMatch
            waitAndAssertTrue(tokenButton, "Token '\(tokenName)' should be visible in source token selector")
            tokenButton.waitAndTap()
            return self
        }
    }

    /// Picks a token via the empty "Choose token" pill, expanding the hosting account group if collapsed.
    @discardableResult
    func chooseTokenFromEmptySelector(_ tokenName: String, accountHeaderLabelPrefix: String = "Main account") -> Self {
        XCTContext.runActivity(named: "Choose token '\(tokenName)' via empty selector") { _ in
            let emptyPill = app.buttons.matching(NSPredicate(format: "label == %@", "Choose token")).firstMatch
            waitAndAssertTrue(emptyPill, "Empty 'Choose token' pill should exist")
            emptyPill.waitAndTap()

            let tokenButton = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: tokenName)].firstMatch
            if !tokenButton.waitForExistence(timeout: .quick) {
                let accountHeader = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", accountHeaderLabelPrefix)).firstMatch
                XCTAssertTrue(
                    accountHeader.waitForExistence(timeout: .robustUIUpdate),
                    "Account header '\(accountHeaderLabelPrefix)' should be displayed in token selector"
                )
                accountHeader.waitAndTap()
            }
            waitAndAssertTrue(tokenButton, "Token '\(tokenName)' should be visible in token selector")
            tokenButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func waitToTokenDisplayed(tokenSymbol: String) -> Self {
        XCTContext.runActivity(named: "Validate 'You receive' section displays token '\(tokenSymbol)'") { _ in
            waitAndAssertTrue(toAmountTextField, "Receive section container should exist")
            let symbolPredicate = NSPredicate(format: "label == %@", tokenSymbol)
            let symbolElement = toAmountTextField.staticTexts.element(matching: symbolPredicate)
            XCTAssertTrue(symbolElement.waitForExistence(timeout: .robustUIUpdate), "Token symbol '\(tokenSymbol)' should be displayed in 'You receive' section")
        }
        return self
    }

    @discardableResult
    func waitForReceiveAccount(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Validate 'You receive' section displays account '\(accountName)'") { _ in
            waitAndAssertTrue(toAmountTextField, "Receive section container should exist")
            let account = toAmountTextField.staticTexts.element(matching: NSPredicate(format: "label == %@", accountName))
            waitAndAssertTrue(account, "Account '\(accountName)' should be displayed in 'You receive' section")
        }
        return self
    }

    @discardableResult
    func waitForConfirmButtonDisabled() -> Self {
        XCTContext.runActivity(named: "Validate confirm button exists and is disabled") { _ in
            waitAndAssertTrue(confirmButton, "Confirm button should exist")
            confirmButton.waitForState(state: .disabled)
        }
        return self
    }

    @discardableResult
    func waitForToTokenNotSelected() -> Self {
        XCTContext.runActivity(named: "Validate 'You receive' section has no token selected") { _ in
            let emptyPill = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonChooseToken)).firstMatch
            waitAndAssertTrue(emptyPill, "Empty 'Choose token' pill should be displayed in 'You receive' section")
        }
        return self
    }

    @discardableResult
    func waitForSwapTokensButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate swap tokens button is displayed") { _ in
            waitAndAssertTrue(swapTokensButton, "Swap tokens button should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForFromAmountValue(_ value: String) -> Self {
        XCTContext.runActivity(named: "Validate from amount text field has value '\(value)'") { _ in
            let field = editableFromAmountField()
            let predicate = NSPredicate(format: "value == %@", value)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: field)
            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)
            XCTAssertEqual(result, .completed, "From amount text field should have value '\(value)'")
        }
        return self
    }

    /// Checks any matching field regardless of hittability, unlike `editableFromAmountField()`.
    @discardableResult
    func waitForFromAmountDisplayedValue(_ value: String, timeout: TimeInterval = .robustUIUpdate) -> Self {
        XCTContext.runActivity(named: "Validate any from amount field displays value '\(value)'") { _ in
            let matches = app.textFields.matching(identifier: SwapAccessibilityIdentifiers.fromAmountTextField)
            let predicate = NSPredicate { _, _ in
                matches.allElementsBoundByIndex.contains { $0.getValue() == value }
            }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
            XCTAssertEqual(result, .completed, "From amount field should display value '\(value)'")
        }
        return self
    }

    @discardableResult
    func clearFromAmount() -> Self {
        XCTContext.runActivity(named: "Clear from amount text field") { _ in
            let field = editableFromAmountField()
            waitForFieldEnabled(field)

            // Tapping an already focused field can resolve to the pass-through twin and dismiss the keyboard.
            if !field.hasFocus {
                field.tap()
            }

            let length = field.getValue().count
            if length > 0 {
                field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: length))
            }
        }
        return self
    }

    @discardableResult
    func tapCloseButton() -> TokenScreen {
        XCTContext.runActivity(named: "Tap close button on Swap screen") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist on Swap screen")
            closeButton.waitAndTap()
            return TokenScreen(app)
        }
    }

    @discardableResult
    func tapCloseButtonAndReturnToMarkets() -> MarketsTokenDetailsScreen {
        XCTContext.runActivity(named: "Tap close button on Swap screen and return to Markets") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist on Swap screen")
            closeButton.waitAndTap()
            return MarketsTokenDetailsScreen(app)
        }
    }

    @discardableResult
    func tapConfirmButton() -> Self {
        XCTContext.runActivity(named: "Tap Swap (confirm) button") { _ in
            waitAndAssertTrue(confirmButton, "Confirm button should exist")
            confirmButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func confirmSwap() -> Self {
        XCTContext.runActivity(named: "Confirm swap by holding the Swap button") { _ in
            let hideKeyboardButton = app.buttons["Hide Keyboard"].firstMatch
            if hideKeyboardButton.waitForExistence(timeout: .quick) {
                hideKeyboardButton.tap()
            }

            waitAndAssertTrue(confirmButton, "Confirm button should exist")
            confirmButton.holdToConfirm(timeout: .networkRequest)
        }
        return self
    }

    @discardableResult
    func waitForConfirmButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Validate confirm button exists and is enabled") { _ in
            waitAndAssertTrue(confirmButton, "Confirm button should exist")
            confirmButton.waitForState(state: .enabled)
        }
        return self
    }

    @discardableResult
    func waitForNotificationShown(title: String? = nil, message: String? = nil) -> Self {
        XCTContext.runActivity(named: "Wait for notification banner with title: '\(title ?? "any")'") { _ in
            switch (title, message) {
            case (.some(let title), .some(let message)):
                XCTAssertTrue(
                    notificationBanner(title: title, message: message).waitForExistence(timeout: .robustUIUpdate),
                    "Notification '\(title)' with message '\(message)' should be shown, shown instead: \(shownNotificationTitles())"
                )

            case (.some(let title), .none):
                XCTAssertTrue(
                    notificationTitle(title).waitForExistence(timeout: .robustUIUpdate),
                    "Notification '\(title)' should be shown on swap screen, shown instead: \(shownNotificationTitles())"
                )

            case (.none, .some(let message)):
                XCTAssertTrue(
                    notificationMessage(message).waitForExistence(timeout: .robustUIUpdate),
                    "Notification message '\(message)' should be shown on swap screen"
                )

            case (.none, .none):
                XCTAssertTrue(notificationTitles.firstMatch.waitForExistence(timeout: .robustUIUpdate), "Notification title should exist on swap screen")
            }
        }
        return self
    }

    @discardableResult
    func waitForFeeCurrencyNavigationButton(label: String) -> Self {
        XCTContext.runActivity(named: "Verify fee notification action button '\(label)'") { _ in
            let button = app.buttons[TokenAccessibilityIdentifiers.feeCurrencyNavigationButton].firstMatch
            waitAndAssertTrue(button, "Fee currency navigation button should exist in the fee notification")
            XCTAssertEqual(button.label, label, "Fee notification action button should be '\(label)' but was '\(button.label)'")
        }
        return self
    }

    @discardableResult
    func waitForNotificationMessageContaining(_ substring: String) -> Self {
        XCTContext.runActivity(named: "Wait for notification message containing '\(substring)'") { _ in
            let message = notificationMessages.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
            waitAndAssertTrue(message, "Notification message containing '\(substring)' should be shown on swap screen")
        }
        return self
    }

    @discardableResult
    func waitForNotificationIcon() -> Self {
        XCTContext.runActivity(named: "Wait for notification icon to be displayed") { _ in
            XCTAssertTrue(notificationIcon.waitForExistence(timeout: .robustUIUpdate), "Notification icon should exist on swap screen")
        }
        return self
    }

    @discardableResult
    func waitForNotificationNotShown() -> Self {
        XCTContext.runActivity(named: "Wait for notification banner to disappear from swap screen") { _ in
            XCTAssertTrue(notificationTitles.firstMatch.waitForNonExistence(timeout: .robustUIUpdate), "Notification title should not exist on swap screen")
        }
        return self
    }

    @discardableResult
    func waitForNotificationNotShown(title: String) -> Self {
        XCTContext.runActivity(named: "Wait for notification '\(title)' to disappear from swap screen") { _ in
            XCTAssertTrue(
                notificationTitle(title).waitForNonExistence(timeout: .robustUIUpdate),
                "Notification '\(title)' should not be shown on swap screen"
            )
        }
        return self
    }

    @discardableResult
    func waitForRetryButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Wait for retry button to be displayed on swap screen") { _ in
            let retryButton = swapContainer.buttons[CommonUIAccessibilityIdentifiers.notificationButton].firstMatch
            waitAndAssertTrue(retryButton, "Retry button should be displayed on swap screen")
        }
        return self
    }

    @discardableResult
    func tapPriceChangeInfoButton() -> Self {
        XCTContext.runActivity(named: "Tap price change info button") { _ in
            waitAndAssertTrue(priceChangeInfoButton, "Price change info button should exist")
            priceChangeInfoButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForPriceChangeWarningDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify price impact warning is displayed") { _ in
            XCTAssertTrue(priceChangeInfoButton.waitForExistence(timeout: .robustUIUpdate), "Price change info button should exist, indicating price impact warning is displayed")
        }
        return self
    }

    @discardableResult
    func waitForInsufficientFundsError() -> Self {
        XCTContext.runActivity(named: "Verify 'Insufficient funds' error is displayed") { _ in
            XCTAssertTrue(insufficientFundsText.waitForExistence(timeout: .robustUIUpdate), "'Insufficient funds' error text should be displayed on swap screen")
        }
        return self
    }

    @discardableResult
    func waitForFeeAmountDisplayed() -> Self {
        XCTContext.runActivity(named: "Wait for fee amount to be displayed") { _ in
            waitAndAssertTrue(feeBlock, "Fee block should exist with fee amount")
        }
        return self
    }

    @discardableResult
    func selectIdenticalReceiveToken(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Select identical receive token '\(tokenName)' to enter Transfer mode") { _ in
            waitAndAssertTrue(receiveTokenSelector, "Receive token selector should exist")
            receiveTokenSelector.waitAndTap()

            // Searching expands all account sections, revealing the identical token regardless of collapse state.
            let searchField = app.searchFields["Search"].firstMatch
            typeWithFocus(into: searchField, text: tokenName)

            let tokenButton = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: tokenName)].firstMatch
            waitAndAssertTrue(tokenButton, "Token '\(tokenName)' should be visible in receive token selector")
            tokenButton.waitAndTap()
            return self
        }
    }

    /// Selects an identical receive token located on a DIFFERENT wallet by first switching to its wallet chip.
    @discardableResult
    func selectIdenticalReceiveToken(_ tokenName: String, onWallet walletName: String) -> Self {
        XCTContext.runActivity(named: "Select identical receive token '\(tokenName)' on wallet '\(walletName)'") { _ in
            waitAndAssertTrue(receiveTokenSelector, "Receive token selector should exist")
            receiveTokenSelector.waitAndTap()

            // The source token is filtered out under its own wallet's chip; the identical token lives under the other wallet's chip.
            let walletChip = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", walletName)).firstMatch
            waitAndAssertTrue(walletChip, "Wallet chip '\(walletName)' should exist in the receive token selector")
            walletChip.tapEvenIfNotHittable()

            let tokenButton = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: tokenName)].firstMatch
            waitAndAssertTrue(tokenButton, "Token '\(tokenName)' should be visible under wallet '\(walletName)'")
            tokenButton.tapEvenIfNotHittable()
            return self
        }
    }

    @discardableResult
    func assertConfirmButtonLabelIsTransfer() -> Self {
        XCTContext.runActivity(named: "Assert action button label is 'Transfer'") { _ in
            waitAndAssertTrue(confirmButton, "Confirm button should exist")
            let expectedLabel = "Transfer"
            let predicate = NSPredicate(format: "label == %@", expectedLabel)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: confirmButton)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Action button label should be '\(expectedLabel)' but was '\(confirmButton.label)'"
            )
        }
        return self
    }

    @discardableResult
    func tapProviderBlock() -> SendSwapProviderSelectorScreen {
        XCTContext.runActivity(named: "Tap provider block to open selector") { _ in
            let providerBlock = app.buttons[SendAccessibilityIdentifiers.swapProviderBlock].firstMatch
            waitAndAssertTrue(providerBlock, "Swap provider block should exist")

            // Settle the keyboard first - a tap while it's still up dismisses it instead of reaching the button underneath.
            let keyboardDismissButton = app.buttons[SwapAccessibilityIdentifiers.keyboardDismissButton].firstMatch
            if keyboardDismissButton.waitForExistence(timeout: .quick) {
                keyboardDismissButton.tap()
                _ = keyboardDismissButton.waitForNonExistence(timeout: .conditional)
            }

            let sheetOpened = NSPredicate { _, _ in
                self.app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "sendSwapProviderSelectorRow_")).firstMatch.exists
            }

            // Target the lower portion of the shared frame, where the always-present compact row's own button actually receives touches.
            let tapOffsets: [CGVector] = [
                CGVector(dx: 0.5, dy: 0.8),
                CGVector(dx: 0.25, dy: 0.65),
                CGVector(dx: 0.75, dy: 0.65),
            ]

            let hittablePredicate = NSPredicate(format: "isHittable == true")

            // Retry with short waits - the row can re-render mid-tap, or the compact row can briefly be non-tappable while quotes load.
            for i in 0 ..< 8 {
                let hittableExpectation = XCTNSPredicateExpectation(predicate: hittablePredicate, object: providerBlock)
                guard XCTWaiter().wait(for: [hittableExpectation], timeout: .quick) == .completed else { continue }

                let offset = tapOffsets[i % tapOffsets.count]
                providerBlock.coordinate(withNormalizedOffset: offset).tap()

                let expectation = XCTNSPredicateExpectation(predicate: sheetOpened, object: nil)
                if XCTWaiter().wait(for: [expectation], timeout: .quick) == .completed {
                    break
                }
            }
        }
        return SendSwapProviderSelectorScreen(app)
    }

    @discardableResult
    func verifyProviderName(contains expected: String) -> Self {
        XCTContext.runActivity(named: "Verify swap provider name contains '\(expected)'") { _ in
            let compactProviderName = app.staticTexts[SendAccessibilityIdentifiers.swapProviderName].firstMatch
            let detailedProviderBlock = detailedProviderBlock()
            let isShown = waitForCondition(timeout: .networkRequest) {
                (compactProviderName.exists && compactProviderName.label.contains(expected))
                    || (detailedProviderBlock.exists && detailedProviderBlock.label.hasPrefix(expected))
            }
            XCTAssertTrue(
                isShown,
                "Provider name should contain '\(expected)' but compact name was '\(compactProviderName.exists ? compactProviderName.label : "absent")' and detailed block was '\(detailedProviderBlock.exists ? detailedProviderBlock.label : "absent")'"
            )
            return self
        }
    }

    @discardableResult
    func waitForProviderBlockNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert provider block is hidden in Transfer mode") { _ in
            let providerBlock = app.descendants(matching: .any)[SendAccessibilityIdentifiers.swapProviderBlock]
            XCTAssertTrue(providerBlock.waitForNonExistence(timeout: .robustUIUpdate), "Provider block should be hidden in Transfer mode")
        }
        return self
    }

    @discardableResult
    func assertConfirmButtonLabelIsSwap() -> Self {
        XCTContext.runActivity(named: "Assert action button label is 'Swap'") { _ in
            waitAndAssertTrue(confirmButton, "Confirm button should exist")
            let predicate = NSPredicate(format: "label == %@", "Swap")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: confirmButton)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Action button label should be 'Swap' but was '\(confirmButton.label)'"
            )
        }
        return self
    }

    @discardableResult
    func waitForMemoFieldNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert manual memo/destination tag field is absent in Transfer mode") { _ in
            let memoField = app.descendants(matching: .any)[SendAccessibilityIdentifiers.additionalFieldTextField]
            XCTAssertTrue(memoField.waitForNonExistence(timeout: .robustUIUpdate), "Manual memo/destination tag field should not exist in Transfer mode")
        }
        return self
    }

    @discardableResult
    func confirmSwapUntilFinishOpened(isNothingSent: () -> Bool) -> SendFinishScreen {
        XCTContext.runActivity(named: "Confirm swap, repeating the hold only while nothing has been sent") { _ in
            let finishScreen = SendFinishScreen(app)
            for _ in 0 ..< Constants.confirmSwapAttempts {
                confirmSwap()
                if finishScreen.isDisplayed(timeout: .conditional) || !isNothingSent() || !confirmButton.exists {
                    break
                }
            }
            return finishScreen.waitForDisplay()
        }
    }

    func confirmTransferAndOpenFinish() -> SendFinishScreen {
        XCTContext.runActivity(named: "Confirm transfer and open finish screen") { _ in
            confirmSwap()
            return SendFinishScreen(app)
        }
    }

    @discardableResult
    func waitForErrorAlert() -> Self {
        XCTContext.runActivity(named: "Assert error alert is shown and finish screen is not opened") { _ in
            let alert = app.alerts[Constants.errorAlertTitle].firstMatch
            waitAndAssertTrue(alert, "Error alert should be displayed")
            waitAndAssertTrue(alert.buttons[Constants.errorAlertButton].firstMatch, "Error alert should offer the OK button")
            let finishHeader = app.staticTexts[SendAccessibilityIdentifiers.finishHeader]
            XCTAssertFalse(finishHeader.exists, "Finish screen should not be opened after a withdrawal error")
        }
        return self
    }

    @discardableResult
    func waitForSendErrorAlert() -> Self {
        XCTContext.runActivity(named: "Assert transaction error alert is shown and finish screen is not opened") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Transaction failed alert should be displayed")
            let finishHeader = app.staticTexts[SendAccessibilityIdentifiers.finishHeader]
            XCTAssertFalse(finishHeader.waitForExistence(timeout: .conditional), "Finish screen should not be opened after a broadcast error")
        }
        return self
    }

    @discardableResult
    func tapAmountFraction(_ token: String) -> Self {
        XCTContext.runActivity(named: "Tap '\(token)' amount fraction chip") { _ in
            var field = editableFromAmountField()
            waitForFieldEnabled(field)
            let chip = app.buttons[SwapAccessibilityIdentifiers.amountFraction(token)].firstMatch
            let valueBeforeTap = field.getValue()
            let attempts = 3
            var applied = false

            // A coordinate tap aimed at the still-animating keyboard accessory lands outside it and only dismisses the keyboard.
            for attempt in 0 ..< attempts {
                // Dismissing the keyboard reorders the field matches, so re-resolve the editable one every attempt.
                field = editableFromAmountField()
                if !field.hasFocus {
                    field.tap()
                }
                waitAndAssertTrue(chip, "'\(token)' amount fraction chip should exist")
                // The chip lives in the keyboard accessory view and is often reported non-hittable, so tap by coordinate.
                if chip.isHittable {
                    chip.tap()
                } else {
                    chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                }

                // Early attempts give up fast to retry a missed tap; the last one waits out a slow quote.
                let timeout: TimeInterval = attempt == attempts - 1 ? .robustUIUpdate : .quick
                applied = field.waitForValue(timeout: timeout) { value in
                    value != valueBeforeTap && value.contains { $0.isNumber && $0 != "0" }
                }

                if applied {
                    break
                }
            }

            XCTAssertTrue(
                applied,
                "'\(token)' amount fraction chip should fill the amount, but it stayed '\(field.getValue())'"
            )
        }
        return self
    }

    @discardableResult
    func tapMaxAmountFraction() -> Self {
        tapAmountFraction("max")
    }

    @discardableResult
    func waitForFromBalanceDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate 'You swap' section displays a balance") { _ in
            // Excludes the fiat amount (which also matches a bare digit check) so a missing balance can't hide behind it.
            let balance = fromContainerElements()
                .matching(NSPredicate(format: "label MATCHES %@ AND NOT (label CONTAINS %@)", ".*[0-9].*", "$"))
                .firstMatch
            waitAndAssertTrue(balance, "A balance value should be displayed in the 'You swap' section")
        }
        return self
    }

    @discardableResult
    func waitForFromFiatAmountDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate 'You swap' section displays a fiat amount") { _ in
            let fiatAmount = fromContainerElements().matching(NSPredicate(format: "label CONTAINS %@", "$")).firstMatch
            waitAndAssertTrue(fiatAmount, "A fiat amount should be displayed in the 'You swap' section")
        }
        return self
    }

    @discardableResult
    func waitForSwapTokensButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Validate swap tokens (reverse) button is enabled") { _ in
            waitAndAssertTrue(swapTokensButton, "Swap tokens button should exist")
            swapTokensButton.waitForState(state: .enabled)
        }
        return self
    }

    @discardableResult
    func waitForFromAmountIsNotZero() -> Self {
        XCTContext.runActivity(named: "Validate from amount is greater than zero") { _ in
            let field = editableFromAmountField()
            let isNotZero = field.waitForValue(timeout: .robustUIUpdate) { value in
                let digits = value.filter { $0.isNumber }
                return !digits.isEmpty && digits.contains { $0 != "0" }
            }
            XCTAssertTrue(isNotZero, "From amount should be greater than zero, but was '\(field.getValue())'")
        }
        return self
    }

    private func notificationTitle(_ title: String) -> XCUIElement {
        notificationTitles.matching(NSPredicate(format: "label == %@", title)).firstMatch
    }

    private func notificationMessage(_ message: String) -> XCUIElement {
        notificationMessages.matching(NSPredicate(format: "label == %@", message)).firstMatch
    }

    private func errorLabel(identifier: String, text: String) -> XCUIElement {
        app.staticTexts
            .matching(identifier: identifier)
            .matching(NSPredicate(format: "label == %@", text))
            .firstMatch
    }

    /// A banner exposes its title and message as one combined label, so the pair is matched on the banner itself.
    private func notificationBanner(title: String, message: String) -> XCUIElement {
        swapContainer.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", title, message))
            .firstMatch
    }

    private func shownNotificationTitles() -> [String] {
        swapContainer.getLabels(identifier: CommonUIAccessibilityIdentifiers.notificationTitle)
    }

    /// Right after choosing tokens the field is briefly disabled while the initial quote loads.
    private func waitForFieldEnabled(_ field: XCUIElement) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: field
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
            .completed,
            "From amount field should become enabled"
        )
    }

    /// Balance/fiat/symbol elements share the `fromAmountTextField` identifier with the editable field itself, excluded here.
    private func fromContainerElements() -> XCUIElementQuery {
        app.descendants(matching: .any)
            .matching(identifier: SwapAccessibilityIdentifiers.fromAmountTextField)
            .matching(NSPredicate(format: "elementType != %d", XCUIElement.ElementType.textField.rawValue))
    }

    private func focusFromAmountField(_ field: XCUIElement) -> Bool {
        waitForFieldEnabled(field)
        field.tap()
        return fromAmountFieldHasKeyboardFocus() || focusedFromAmountField.waitForExistence(timeout: Constants.keyboardFocusTimeout)
    }

    private func focusFromAmountFieldStably(_ field: XCUIElement) -> Bool {
        guard focusFromAmountField(field) else {
            return false
        }
        _ = app.keyboards.firstMatch.waitForExistence(timeout: Constants.keyboardFocusTimeout)
        return !focusedFromAmountField.waitForNonExistence(timeout: Constants.focusSettleTimeout)
    }

    private func enteredFromAmountLength(_ field: XCUIElement) -> Int {
        let value = field.getValue()
        return value == field.placeholderValue ? 0 : value.count
    }

    private func fromAmountFieldHasKeyboardFocus() -> Bool {
        focusedFromAmountField.exists
    }

    private var focusedFromAmountField: XCUIElement {
        app.textFields
            .matching(identifier: SwapAccessibilityIdentifiers.fromAmountTextField)
            .matching(NSPredicate(format: "hasKeyboardFocus == true"))
            .firstMatch
    }

    private func editableFromAmountField() -> XCUIElement {
        // The editable field is the hittable match; the overlaid measurement field disables hit testing.
        let query = app.textFields.matching(identifier: SwapAccessibilityIdentifiers.fromAmountTextField)

        guard let field = query.firstHittableElement() else {
            XCTFail("Editable from amount field should become hittable")
            return query.firstMatch
        }

        return field
    }
}

// MARK: - Gasless (fee token selection)

extension SwapScreen {
    @discardableResult
    func openFeeSelector() -> SendFeeSelectorScreen {
        XCTContext.runActivity(named: "Open the 'Network fee' bottom sheet") { _ in
            waitAndAssertTrue(feeBlock, "Fee block should exist")
            feeBlock.waitAndTap()
        }
        return SendFeeSelectorScreen(app)
    }

    @discardableResult
    func switchFeeTokenAndApply(currentFeeToken: String, newFeeToken: String) -> Self {
        openFeeSelector()
            .waitForNetworkFeeSheet()
            .openTokenSelector(fromCoinSymbol: currentFeeToken)
            .waitForChooseTokenSheet()
            .selectFeeToken(symbol: newFeeToken)
            .applyReturningToSwap()
        return self
    }

    @discardableResult
    func assertBestRateDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert 'Best rate' badge is displayed") { _ in
            let badge = app.descendants(matching: .any)[SendAccessibilityIdentifiers.swapProviderBestRateBadge].firstMatch
            waitAndAssertTrue(badge, "'Best rate' badge should be displayed on the swap screen")
        }
        return self
    }

    func captureReceiveAmount() -> String {
        XCTContext.runActivity(named: "Capture the received amount before changing the fee token") { _ in
            waitAndAssertTrue(receiveAmountValue, "Receive amount should be present to capture")
            return receiveAmountValue.label
        }
    }

    @discardableResult
    func assertReceiveAmount(equals expected: String) -> Self {
        XCTContext.runActivity(named: "Assert the received amount equals '\(expected)'") { _ in
            waitAndAssertTrue(receiveAmountValue, "Receive amount should be present")
            let isEqual = waitForCondition(timeout: .robustUIUpdate) { self.receiveAmountValue.label == expected }
            XCTAssertTrue(isEqual, "Receive amount should remain '\(expected)' but was '\(receiveAmountValue.label)'")
        }
        return self
    }

    @discardableResult
    func assertReceiveAmount(notEquals unexpected: String) -> Self {
        XCTContext.runActivity(named: "Assert the received amount is not '\(unexpected)'") { _ in
            waitAndAssertTrue(receiveAmountValue, "Receive amount should be present")
            let isDifferent = waitForCondition(timeout: .robustUIUpdate) {
                let label = self.receiveAmountValue.label
                guard label != unexpected else { return false }
                let digits = label.filter { $0.isNumber }
                return !digits.isEmpty && digits.contains { $0 != "0" }
            }
            XCTAssertTrue(
                isDifferent,
                "Receive amount should have recalculated to a non-zero value different from '\(unexpected)', but was '\(receiveAmountValue.label)'"
            )
        }
        return self
    }

    func captureFeeAmount() -> String {
        XCTContext.runActivity(named: "Capture the network fee amount") { _ in
            let feeAmountText = app.staticTexts[SendAccessibilityIdentifiers.networkFeeAmount].firstMatch
            waitAndAssertTrue(feeAmountText, "Network fee amount should be present to capture")
            return feeAmountText.label
        }
    }

    @discardableResult
    func assertFeeAmount(notEquals unexpected: String) -> Self {
        XCTContext.runActivity(named: "Assert the network fee amount is not '\(unexpected)'") { _ in
            let feeAmountText = app.staticTexts[SendAccessibilityIdentifiers.networkFeeAmount].firstMatch
            waitAndAssertTrue(feeAmountText, "Network fee amount should be present")
            let isDifferent = waitForCondition(timeout: .robustUIUpdate) { feeAmountText.label != unexpected }
            XCTAssertTrue(isDifferent, "Network fee amount should differ from '\(unexpected)'")
        }
        return self
    }

    @discardableResult
    func assertFeeCurrencySymbol(_ symbol: String) -> Self {
        XCTContext.runActivity(named: "Assert the network fee is shown in '\(symbol)'") { _ in
            let badge = app.staticTexts[SendAccessibilityIdentifiers.networkFeeCurrencySymbol].firstMatch
            waitAndAssertTrue(badge, "Fee currency badge should exist")
            XCTAssertEqual(badge.label, symbol, "Network fee should be shown in '\(symbol)' but badge was '\(badge.label)'")
        }
        return self
    }

    @discardableResult
    func waitForFeeCurrencySymbol(_ symbol: String) -> Self {
        XCTContext.runActivity(named: "Wait for the network fee to be shown in '\(symbol)'") { _ in
            let badge = app.staticTexts[SendAccessibilityIdentifiers.networkFeeCurrencySymbol].firstMatch
            waitAndAssertTrue(badge, "Fee currency badge should exist")
            let isShown = waitForCondition(timeout: .networkRequest) { badge.label == symbol }
            XCTAssertTrue(isShown, "Network fee should be shown in '\(symbol)' but badge was '\(badge.label)'")
        }
        return self
    }

    @discardableResult
    func assertFeeAmountContainsFiat(_ fiatSign: String = "$") -> Self {
        XCTContext.runActivity(named: "Assert the fee amount shows its fiat ('\(fiatSign)') equivalent") { _ in
            let feeAmount = app.staticTexts[SendAccessibilityIdentifiers.networkFeeAmount].firstMatch
            waitAndAssertTrue(feeAmount, "Network fee amount element should exist")
            let containsFiat = waitForCondition(timeout: .robustUIUpdate) { feeAmount.label.contains(fiatSign) }
            XCTAssertTrue(containsFiat, "Fee amount should contain '\(fiatSign)' but was '\(feeAmount.label)'")
        }
        return self
    }

    @discardableResult
    func assertNetworkFeeBlockDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert the 'Network fee' block is displayed") { _ in
            waitAndAssertTrue(feeBlock, "Network fee block should be displayed on the swap screen")
        }
        return self
    }

    @discardableResult
    func assertNoInsufficientFundsError() -> Self {
        XCTContext.runActivity(named: "Assert no 'Insufficient funds' error is displayed") { _ in
            XCTAssertTrue(
                insufficientFundsText.waitForNonExistence(timeout: .robustUIUpdate),
                "'Insufficient funds' error should not be displayed when the fee is reserved from the amount"
            )
        }
        return self
    }

    private func waitForCondition(timeout: TimeInterval, _ condition: @escaping () -> Bool) -> Bool {
        let predicate = NSPredicate { _, _ in condition() }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

extension SwapScreen {
    @discardableResult
    func assertFromAmountIsZero() -> Self {
        XCTContext.runActivity(named: "Assert the send amount is zero") { _ in
            let field = editableFromAmountField()
            let isZero = field.waitForValue(timeout: .robustUIUpdate) { value in
                value.isEmpty ? field.placeholderValue == Constants.zeroPlaceholder : self.isZeroAmount(value)
            }
            XCTAssertTrue(isZero, "Send amount should be zero, but was '\(field.getValue())'")
        }
        return self
    }

    @discardableResult
    func assertReceiveTokenNotSelected() -> Self {
        XCTContext.runActivity(named: "Assert the receive token is not selected") { _ in
            let emptyPill = app.buttons.matching(NSPredicate(format: "label == %@", Constants.chooseTokenLabel)).firstMatch
            waitAndAssertTrue(emptyPill, "'\(Constants.chooseTokenLabel)' should be displayed in the 'To' block")
        }
        return self
    }

    @discardableResult
    func assertFromFiatAmountIsZero() -> Self {
        XCTContext.runActivity(named: "Assert the send amount fiat equivalent is zero") { _ in
            let fiatAmount = fromContainerElements().matching(NSPredicate(format: "label CONTAINS %@", Constants.fiatSign)).firstMatch
            waitAndAssertTrue(fiatAmount, "Send amount fiat equivalent should be displayed")
            XCTAssertTrue(isZeroAmount(fiatAmount.label), "Send amount fiat equivalent should be zero, but was '\(fiatAmount.label)'")
        }
        return self
    }

    @discardableResult
    func assertReceiveAmountIsZero() -> Self {
        XCTContext.runActivity(named: "Assert the receive amount is zero") { _ in
            waitAndAssertTrue(receiveAmountValue, "Receive amount should be displayed")
            XCTAssertTrue(isZeroAmount(receiveAmountValue.label), "Receive amount should be zero, but was '\(receiveAmountValue.label)'")
        }
        return self
    }

    @discardableResult
    func assertReceiveFiatAmountIsZero() -> Self {
        XCTContext.runActivity(named: "Assert the receive amount fiat equivalent is zero") { _ in
            let fiatAmount = receiveFiatAmount()
            waitAndAssertTrue(fiatAmount, "Receive amount fiat equivalent should be displayed")
            XCTAssertTrue(isZeroAmount(fiatAmount.label), "Receive amount fiat equivalent should be zero, but was '\(fiatAmount.label)'")
        }
        return self
    }

    @discardableResult
    func assertReceiveAmountIsNotZero() -> Self {
        XCTContext.runActivity(named: "Assert the receive amount is calculated") { _ in
            waitAndAssertTrue(receiveAmountValue, "Receive amount should be displayed")
            let isCalculated = waitForCondition(timeout: .robustUIUpdate) { self.hasNonZeroDigit(self.receiveAmountValue.label) }
            XCTAssertTrue(isCalculated, "Receive amount should be greater than zero, but was '\(receiveAmountValue.label)'")
        }
        return self
    }

    @discardableResult
    func assertAmountFractionsDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert the 25%, 50%, 75% and Max amount buttons are displayed") { _ in
            let chips = Constants.amountFractionTokens.map { app.buttons[SwapAccessibilityIdentifiers.amountFraction($0)].firstMatch }
            for _ in 0 ..< Constants.focusAttempts {
                let field = editableFromAmountField()
                waitForFieldEnabled(field)
                if !field.hasFocus {
                    field.tap()
                }
                if chips.allSatisfy({ $0.waitForExistence(timeout: .quick) }) {
                    break
                }
            }
            for (token, chip) in zip(Constants.amountFractionTokens, chips) {
                XCTAssertTrue(chip.exists, "'\(token)' amount button should be displayed")
            }
        }
        return self
    }

    func captureLoadedFeeAmount() -> String {
        XCTContext.runActivity(named: "Capture the loaded network fee amount") { _ in
            let feeAmountText = app.staticTexts[SendAccessibilityIdentifiers.networkFeeAmount].firstMatch
            waitAndAssertTrue(feeAmountText, "Network fee amount should be present to capture")
            let isLoaded = waitForCondition(timeout: .networkRequest) {
                feeAmountText.exists && feeAmountText.label.contains(Constants.fiatSign)
            }
            XCTAssertTrue(isLoaded, "Network fee amount should be loaded, but was '\(feeAmountText.label)'")
            return feeAmountText.label
        }
    }

    @discardableResult
    func assertLoadedFeeAmount(notEquals unexpected: String) -> Self {
        XCTContext.runActivity(named: "Assert the loaded network fee amount is not '\(unexpected)'") { _ in
            let feeAmountText = app.staticTexts[SendAccessibilityIdentifiers.networkFeeAmount].firstMatch
            waitAndAssertTrue(feeAmountText, "Network fee amount should be present")
            let isRecalculated = waitForCondition(timeout: .networkRequest) {
                guard feeAmountText.exists else { return false }
                let label = feeAmountText.label
                return label.contains(Constants.fiatSign) && label != unexpected
            }
            XCTAssertTrue(isRecalculated, "Network fee amount should be recalculated from '\(unexpected)', but was '\(feeAmountText.label)'")
        }
        return self
    }

    @discardableResult
    func waitForNonZeroNetworkFee() -> Self {
        XCTContext.runActivity(named: "Wait for a non-zero network fee to load") { _ in
            let feeAmountText = app.staticTexts[SendAccessibilityIdentifiers.networkFeeAmount].firstMatch
            waitAndAssertTrue(feeAmountText, timeout: .networkRequest, "Network fee amount should be displayed")
            let isLoaded = waitForCondition(timeout: .networkRequest) {
                guard feeAmountText.exists else { return false }
                let label = feeAmountText.label
                return label.contains(Constants.fiatSign) && label.range(of: "[1-9]", options: .regularExpression) != nil
            }
            XCTAssertTrue(isLoaded, "Network fee should load as a non-zero amount, but was '\(feeAmountText.label)'")
        }
        return self
    }

    @discardableResult
    func waitForZeroNetworkFee() -> Self {
        XCTContext.runActivity(named: "Wait for the network fee to load as zero") { _ in
            let feeAmountText = app.staticTexts[SendAccessibilityIdentifiers.networkFeeAmount].firstMatch
            waitAndAssertTrue(feeAmountText, timeout: .networkRequest, "Network fee amount should be displayed")
            let isZero = waitForCondition(timeout: .networkRequest) {
                guard feeAmountText.exists else { return false }
                let label = feeAmountText.label
                return label.contains("0") && label.range(of: "[1-9]", options: .regularExpression) == nil
            }
            XCTAssertTrue(isZero, "Network fee should be zero, but was '\(feeAmountText.label)'")
        }
        return self
    }

    @discardableResult
    func tapCurrencyToggle() -> Self {
        XCTContext.runActivity(named: "Tap the send amount fiat equivalent to switch the input currency") { _ in
            let toggle = currencyToggleButton()
            waitAndAssertTrue(toggle, "Currency toggle should be displayed under the send amount")
            toggle.waitAndTap()
        }
        return self
    }

    func captureFromFiatEquivalent() -> String {
        XCTContext.runActivity(named: "Capture the fiat equivalent displayed under the send amount") { _ in
            let toggle = currencyToggleButton()
            waitAndAssertTrue(toggle, "Fiat equivalent should be displayed under the send amount")
            let isCalculated = waitForCondition(timeout: .robustUIUpdate) {
                toggle.exists && toggle.label.contains(Constants.fiatSign) && self.hasNonZeroDigit(toggle.label)
            }
            XCTAssertTrue(isCalculated, "Fiat equivalent under the send amount should be calculated, but was '\(toggle.label)'")
            return toggle.label
        }
    }

    func captureFromTokenEquivalent() -> String {
        XCTContext.runActivity(named: "Capture the token equivalent displayed under the send amount") { _ in
            assertFromAlternativeAmountIsInToken()
            return currencyToggleButton().label
        }
    }

    @discardableResult
    func assertFromAlternativeAmountIsInToken() -> Self {
        XCTContext.runActivity(named: "Assert the equivalent under the send amount is shown in the token") { _ in
            let toggle = currencyToggleButton()
            waitAndAssertTrue(toggle, "Equivalent should be displayed under the send amount")
            let isInToken = waitForCondition(timeout: .robustUIUpdate) {
                toggle.exists && !toggle.label.contains(Constants.fiatSign) && self.hasNonZeroDigit(toggle.label)
            }
            XCTAssertTrue(isInToken, "Equivalent under the send amount should be a token amount, but was '\(toggle.label)'")
        }
        return self
    }

    @discardableResult
    func assertFromAlternativeAmountInToken(notEquals unexpected: String) -> Self {
        XCTContext.runActivity(named: "Assert the token equivalent under the send amount is recalculated") { _ in
            let toggle = currencyToggleButton()
            waitAndAssertTrue(toggle, "Equivalent should be displayed under the send amount")
            let isRecalculated = waitForCondition(timeout: .robustUIUpdate) {
                guard toggle.exists else { return false }
                let label = toggle.label
                return label != unexpected && !label.contains(Constants.fiatSign) && self.hasNonZeroDigit(label)
            }
            XCTAssertTrue(isRecalculated, "Token equivalent under the send amount should differ from '\(unexpected)', but was '\(toggle.label)'")
        }
        return self
    }

    @discardableResult
    func assertFromAmountContainsDigits(of amount: String) -> Self {
        XCTContext.runActivity(named: "Assert the send amount field shows '\(amount)'") { _ in
            let expectedDigits = amount.filter { $0.isNumber || $0 == "." }
            let field = editableFromAmountField()
            let matches = field.waitForValue(timeout: .robustUIUpdate) { $0.filter { $0.isNumber || $0 == "." }.contains(expectedDigits) }
            XCTAssertTrue(matches, "Send amount field should show '\(amount)', but was '\(field.getValue())'")
        }
        return self
    }

    func captureProviderRate() -> String {
        XCTContext.runActivity(named: "Capture the provider rate") { _ in
            let providerBlock = detailedProviderBlock()
            waitAndAssertTrue(providerBlock, timeout: .networkRequest, "Detailed provider block should be displayed")
            let hasRate = waitForCondition(timeout: .networkRequest) { providerBlock.exists && providerBlock.label.contains(Constants.rateSign) }
            XCTAssertTrue(hasRate, "Provider block should show the rate, but was '\(providerBlock.label)'")
            return providerBlock.label
        }
    }

    @discardableResult
    func assertProviderRate(notEquals unexpected: String) -> Self {
        XCTContext.runActivity(named: "Assert the provider rate is recalculated") { _ in
            let providerBlock = detailedProviderBlock()
            waitAndAssertTrue(providerBlock, "Detailed provider block should be displayed")
            let isRecalculated = waitForCondition(timeout: .networkRequest) {
                providerBlock.exists && providerBlock.label != unexpected && providerBlock.label.contains(Constants.rateSign)
            }
            XCTAssertTrue(isRecalculated, "Provider rate should differ from '\(unexpected)', but was '\(providerBlock.label)'")
        }
        return self
    }

    @discardableResult
    func assertDetailedModeDisplayed(providerName: String) -> Self {
        XCTContext.runActivity(named: "Assert the detailed mode shows the receive fiat amount and the provider '\(providerName)' with type, 'Best rate' badge and rate") { _ in
            waitAndAssertTrue(receiveFiatAmount(), "A fiat amount should be displayed in the 'You receive' section in the detailed mode")
            let providerBlock = detailedProviderBlock()
            waitAndAssertTrue(providerBlock, timeout: .networkRequest, "Detailed provider block should be displayed")
            let isComplete = waitForCondition(timeout: .networkRequest) {
                guard providerBlock.exists else { return false }
                let label = providerBlock.label
                let hasType = Constants.providerTypes.contains { label.contains($0) }
                return label.hasPrefix(providerName) && hasType && label.contains(Constants.bestRateBadge) && label.contains(Constants.rateSign)
            }
            XCTAssertTrue(
                isComplete,
                "Detailed provider block should show '\(providerName)', the type, 'Best rate' and the rate, but was '\(providerBlock.label)'"
            )
        }
        return self
    }

    @discardableResult
    func assertSimpleModeDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert the simple mode shows the compact provider block without the receive fiat amount") { _ in
            let providerName = app.staticTexts[SendAccessibilityIdentifiers.swapProviderName].firstMatch
            waitAndAssertTrue(providerName, timeout: .networkRequest, "Simple provider block should be displayed")
            XCTAssertTrue(
                receiveFiatAmount().waitForNonExistence(timeout: .robustUIUpdate),
                "Fiat amount should not be displayed in the 'You receive' section in the simple mode"
            )
        }
        return self
    }

    @discardableResult
    func selectFormVariant(_ variant: String) -> Self {
        XCTContext.runActivity(named: "Select '\(variant)' in the swap mode menu") { _ in
            openFormVariantMenu()
            let item = formVariantMenuItem(variant)
            waitAndAssertTrue(item, "'\(variant)' item should be displayed in the swap mode menu")
            item.tap()
            XCTAssertTrue(item.waitForNonExistence(timeout: .robustUIUpdate), "Swap mode menu should be closed")
        }
        return self
    }

    @discardableResult
    func openFormVariantMenu() -> Self {
        XCTContext.runActivity(named: "Open the swap mode menu") { _ in
            let hideKeyboardButton = app.buttons[SwapAccessibilityIdentifiers.keyboardDismissButton].firstMatch
            if hideKeyboardButton.waitForExistence(timeout: .quick) {
                hideKeyboardButton.tap()
                _ = hideKeyboardButton.waitForNonExistence(timeout: .conditional)
            }
            let menuButton = app.buttons[SendAccessibilityIdentifiers.formVariantMenuButton].firstMatch
            waitAndAssertTrue(menuButton, "Swap mode menu button should be displayed")
            menuButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func assertFormVariantMenuItems(selected: String, notSelected: String) -> Self {
        XCTContext.runActivity(named: "Assert '\(selected)' is selected and '\(notSelected)' is not in the swap mode menu") { _ in
            let selectedItem = formVariantMenuItem(selected)
            let notSelectedItem = formVariantMenuItem(notSelected)
            waitAndAssertTrue(selectedItem, "'\(selected)' item should be displayed in the swap mode menu")
            waitAndAssertTrue(notSelectedItem, "'\(notSelected)' item should be displayed in the swap mode menu")
            XCTAssertTrue(selectedItem.isSelected, "'\(selected)' item should be selected")
            XCTAssertFalse(notSelectedItem.isSelected, "'\(notSelected)' item should not be selected")
        }
        return self
    }

    @discardableResult
    func tapFormVariantMenuItem(_ variant: String) -> Self {
        XCTContext.runActivity(named: "Tap '\(variant)' in the swap mode menu") { _ in
            let item = formVariantMenuItem(variant)
            waitAndAssertTrue(item, "'\(variant)' item should be displayed in the swap mode menu")
            item.tap()
        }
        return self
    }

    @discardableResult
    func assertFormVariantMenuClosed(_ variant: String) -> Self {
        XCTContext.runActivity(named: "Assert the swap mode menu is closed") { _ in
            XCTAssertTrue(formVariantMenuItem(variant).waitForNonExistence(timeout: .robustUIUpdate), "Swap mode menu should be closed")
        }
        return self
    }

    private func currencyToggleButton() -> XCUIElement {
        app.buttons
            .matching(identifier: SwapAccessibilityIdentifiers.fromAmountTextField)
            .matching(NSPredicate(format: "NOT (label CONTAINS %@)", Constants.tokenSelectorChevron))
            .firstMatch
    }

    private func detailedProviderBlock() -> XCUIElement {
        app.buttons[SendAccessibilityIdentifiers.swapProviderBlock].firstMatch
    }

    private func receiveFiatAmount() -> XCUIElement {
        toAmountTextField.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", Constants.fiatSign)).firstMatch
    }

    private func formVariantMenuItem(_ variant: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", variant)).firstMatch
    }

    private func isZeroAmount(_ label: String) -> Bool {
        let digits = label.filter(\.isNumber)
        return !digits.isEmpty && digits.allSatisfy { $0 == "0" }
    }

    private func hasNonZeroDigit(_ label: String) -> Bool {
        label.contains { $0.isNumber && $0 != "0" }
    }
}

enum FeeOptionType: String {
    case normal = "Normal"
    case priority = "Priority"
}

enum SwapScreenElement: String, UIElement {
    case title
    case fromAmountTextField
    case toAmountTextField
    case feeBlock
    case normalFeeOption
    case priorityFeeOption
    case swapTokensButton
    case confirmButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return SwapAccessibilityIdentifiers.title
        case .fromAmountTextField:
            return SwapAccessibilityIdentifiers.fromAmountTextField
        case .toAmountTextField:
            return SwapAccessibilityIdentifiers.toAmountTextField
        case .feeBlock:
            return SwapAccessibilityIdentifiers.feeBlock
        case .normalFeeOption:
            return FeeAccessibilityIdentifiers.marketFeeOption
        case .priorityFeeOption:
            return FeeAccessibilityIdentifiers.fastFeeOption
        case .swapTokensButton:
            return SwapAccessibilityIdentifiers.swapTokensButton
        case .confirmButton:
            return SwapAccessibilityIdentifiers.confirmButton
        }
    }
}

private extension SwapScreen {
    enum Constants {
        static let errorAlertTitle = "Error"
        static let errorAlertButton = "OK"
        static let keyboardFocusTimeout: TimeInterval = 3
        static let focusSettleTimeout: TimeInterval = 1
        static let focusAttempts = 3
        static let confirmSwapAttempts = 3
        static let fiatSign = "$"
        static let zeroPlaceholder = "0"
        static let tokenSelectorChevron = "chevronDownMini"
        static let chooseTokenLabel = "Choose token"
        static let rateSign = "≈"
        static let bestRateBadge = "Best rate"
        static let providerTypes = ["CEX", "DEX"]
        static let amountFractionTokens = ["25", "50", "75", "max"]
    }
}
