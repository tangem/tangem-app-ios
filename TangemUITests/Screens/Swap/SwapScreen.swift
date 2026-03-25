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
    private lazy var feeBlock = button(.feeBlock)
    private lazy var normalFeeOption = button(.normalFeeOption)
    private lazy var priorityFeeOption = button(.priorityFeeOption)
    private lazy var swapTokensButton = button(.swapTokensButton)
    private lazy var confirmButton = button(.confirmButton)
    private lazy var chooseSpeedTitle = app.staticTexts[FeeAccessibilityIdentifiers.feeSelectorChooseSpeedTitle]
    private lazy var closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch
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
            XCTAssertTrue(fromAmountTextField.waitForExistence(timeout: .robustUIUpdate), "From amount text field should exist")

            fromAmountTextField.tap()
            fromAmountTextField.typeText(amount)
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
            waitAndAssertTrue(fromAmountTextField, "From amount text field should exist")
            let predicate = NSPredicate(format: "value == %@", value)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: fromAmountTextField)
            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)
            XCTAssertEqual(result, .completed, "From amount text field should have value '\(value)'")
        }
        return self
    }

    @discardableResult
    func clearFromAmount() -> Self {
        XCTContext.runActivity(named: "Clear from amount text field") { _ in
            waitAndAssertTrue(fromAmountTextField, "From amount text field should exist")
            deleteText(element: fromAmountTextField)
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
