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
    private lazy var holdConfirmButton = otherElement(.confirmButton)
    private lazy var chooseSpeedTitle = app.staticTexts[FeeAccessibilityIdentifiers.feeSelectorChooseSpeedTitle]
    private lazy var closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch
    private lazy var fromTokenSelector = app.buttons.matching(
        NSPredicate(format: "identifier == %@ AND label CONTAINS %@", SwapAccessibilityIdentifiers.fromAmountTextField, "chevronDownMini")
    ).firstMatch
    private lazy var receiveTokenSelector = app.buttons[SwapAccessibilityIdentifiers.tokenSelector].firstMatch
    private lazy var priceChangeInfoButton = app.buttons[SwapAccessibilityIdentifiers.priceChangeInfoButton].firstMatch

    private lazy var swapContainer = app.scrollViews[SwapAccessibilityIdentifiers.title]
    private lazy var notificationTitle = swapContainer.staticTexts[CommonUIAccessibilityIdentifiers.notificationTitle]
    private lazy var notificationMessage = swapContainer.staticTexts[CommonUIAccessibilityIdentifiers.notificationMessage]
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
            let field = editableFromAmountField()
            // The field formats the value with grouping separators, so compare on digits and the decimal separator only.
            let expectedDigits = amount.filter { $0.isNumber || $0 == "." }
            // [REDACTED_INFO]: the field resigns focus on swap-state re-renders, so clear, refocus and retype until it sticks.
            for attempt in 0 ..< 8 {
                if attempt > 0 || !field.hasFocus {
                    field.tap()
                }
                let length = field.getValue().count
                if length > 0 {
                    field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: length))
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
    func selectFeeOption(_ option: FeeOptionType) -> Self {
        XCTContext.runActivity(named: "Select \(option.rawValue) fee option") { _ in
            let targetButton = option == .normal ? normalFeeOption : priorityFeeOption
            XCTAssertTrue(targetButton.waitForExistence(timeout: .robustUIUpdate), "\(option.rawValue) fee option should exist")
            targetButton.tap()
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
            if let title = title {
                let titleLabel = app.staticTexts[CommonUIAccessibilityIdentifiers.notificationTitle]
                XCTAssertTrue(titleLabel.waitForExistence(timeout: .robustUIUpdate), "Error title should exist")
                XCTAssertEqual(titleLabel.label, title, "Error title should be '\(title)' but was '\(titleLabel.label)'")
            }

            if let message = message {
                let messageLabel = app.staticTexts[CommonUIAccessibilityIdentifiers.notificationMessage]
                XCTAssertTrue(messageLabel.waitForExistence(timeout: .robustUIUpdate), "Error message should exist")
                XCTAssertEqual(messageLabel.label, message, "Error message should be '\(message)' but was '\(messageLabel.label)'")
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
    func waitForConfirmButtonDisabled() -> Self {
        XCTContext.runActivity(named: "Validate confirm button exists and is disabled") { _ in
            waitAndAssertTrue(confirmButton, "Confirm button should exist")
            confirmButton.waitForState(state: .disabled)
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

    @discardableResult
    func clearFromAmount() -> Self {
        XCTContext.runActivity(named: "Clear from amount text field") { _ in
            let field = editableFromAmountField()
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

    /// Confirms the swap by tap (cold wallet) or press-and-hold (hot wallet); dismisses the number-pad first.
    @discardableResult
    func confirmSwap() -> Self {
        XCTContext.runActivity(named: "Confirm swap (tap or hold)") { _ in
            let hideKeyboardButton = app.buttons["Hide Keyboard"].firstMatch
            if hideKeyboardButton.waitForExistence(timeout: .quick) {
                hideKeyboardButton.tap()
            }

            // Hold button appears only after source token finishes loading; tapping the regular button earlier throws "Loading in process".
            if holdConfirmButton.waitForExistence(timeout: .networkRequest) {
                holdConfirmButton.press(forDuration: 4.0)
                return
            }
            waitAndAssertTrue(confirmButton, "Confirm button should exist and be ready")
            confirmButton.waitAndTap()
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
            XCTAssertTrue(notificationTitle.waitForExistence(timeout: .robustUIUpdate), "Notification title should exist on swap screen")

            if let title {
                XCTAssertEqual(notificationTitle.label, title, "Notification title should be '\(title)' but was '\(notificationTitle.label)'")
            }

            if let message {
                XCTAssertTrue(notificationMessage.waitForExistence(timeout: .robustUIUpdate), "Notification message should exist on swap screen")
                XCTAssertEqual(notificationMessage.label, message, "Notification message should be '\(message)' but was '\(notificationMessage.label)'")
            }
        }
        return self
    }

    @discardableResult
    func waitForNotificationMessageContaining(_ substring: String) -> Self {
        XCTContext.runActivity(named: "Wait for notification message containing '\(substring)'") { _ in
            XCTAssertTrue(notificationMessage.waitForExistence(timeout: .robustUIUpdate), "Notification message should exist on swap screen")
            let predicate = NSPredicate(format: "label CONTAINS %@", substring)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: notificationMessage)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Notification message should contain '\(substring)' but was '\(notificationMessage.label)'"
            )
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
            XCTAssertTrue(notificationTitle.waitForNonExistence(timeout: .robustUIUpdate), "Notification title should not exist on swap screen")
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
    func waitForAlertAndDismiss() -> Self {
        XCTContext.runActivity(named: "Wait for alert and dismiss") { _ in
            let alert = app.alerts.firstMatch
            XCTAssertTrue(alert.waitForExistence(timeout: .robustUIUpdate), "Alert should be displayed")

            alert.buttons["OK"].waitAndTap()
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

            let tokenButton = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: tokenName)].firstMatch
            if !tokenButton.waitForExistence(timeout: .quick) {
                let accountCard = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Account")).firstMatch
                waitAndAssertTrue(accountCard, "An account card should be visible in the receive token selector")
                accountCard.waitAndTap()
            }
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
    func confirmTransferAndOpenFinish() -> SendFinishScreen {
        XCTContext.runActivity(named: "Confirm transfer and open finish screen") { _ in
            confirmSwap()
            return SendFinishScreen(app)
        }
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
    func tapMaxAmountFraction() -> Self {
        XCTContext.runActivity(named: "Tap Max amount fraction chip") { _ in
            let field = editableFromAmountField()
            if !field.hasFocus {
                field.tap()
            }
            let maxChip = app.buttons[SwapAccessibilityIdentifiers.amountFraction("max")].firstMatch
            waitAndAssertTrue(maxChip, "Max amount fraction chip should exist")
            // The chip lives in the keyboard accessory view and is often reported non-hittable, so tap by coordinate.
            if maxChip.isHittable {
                maxChip.tap()
            } else {
                maxChip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
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

    private func editableFromAmountField() -> XCUIElement {
        // The editable field is the hittable match; the overlaid measurement field disables hit testing.
        let query = app.textFields.matching(identifier: SwapAccessibilityIdentifiers.fromAmountTextField)
        let predicate = NSPredicate { _, _ in query.allElementsBoundByIndex.contains { $0.isHittable } }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
            .completed,
            "Editable from amount field should become hittable"
        )
        return query.allElementsBoundByIndex.first { $0.isHittable } ?? query.firstMatch
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
    func assertFeeCurrencySymbol(_ symbol: String) -> Self {
        XCTContext.runActivity(named: "Assert the network fee is shown in '\(symbol)'") { _ in
            let badge = app.staticTexts[SendAccessibilityIdentifiers.networkFeeCurrencySymbol].firstMatch
            waitAndAssertTrue(badge, "Fee currency badge should exist")
            XCTAssertEqual(badge.label, symbol, "Network fee should be shown in '\(symbol)' but badge was '\(badge.label)'")
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
