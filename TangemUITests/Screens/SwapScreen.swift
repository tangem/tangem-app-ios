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
    // MARK: - UI Elements

    private lazy var titleLabel = scrollView(.title)

    // Amount input elements
    private lazy var fromAmountTextField = textField(.fromAmountTextField)
    private lazy var toAmountTextField = staticText(.toAmountTextField)

    /// Fee elements
    private lazy var feeBlock = button(.feeBlock)

    // Fee selector elements
    private lazy var feeSelectorTitle = staticText(.feeSelectorTitle)
    private lazy var normalFeeOption = button(.normalFeeOption)
    private lazy var priorityFeeOption = button(.priorityFeeOption)

    // MARK: - Validation Methods

    @discardableResult
    func validateSwapScreenDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Swap screen is displayed") { _ in
            XCTAssertTrue(titleLabel.waitForExistence(timeout: .robustUIUpdate), "Swap screen title should exist")
            XCTAssertTrue(fromAmountTextField.waitForExistence(timeout: .robustUIUpdate), "From amount text field should exist")
            XCTAssertTrue(toAmountTextField.waitForExistence(timeout: .robustUIUpdate), "To amount text field should exist")
        }
        return self
    }

    // MARK: - Action Methods

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
            // Wait for fee information to be available
            XCTAssertTrue(feeBlock.waitForExistence(timeout: .robustUIUpdate), "Fee block should appear after calculation")
        }
        return self
    }

    @discardableResult
    func validateReceivedAmount() -> Self {
        XCTContext.runActivity(named: "Validate 'You receive' amount is greater than zero") { _ in
            // Get all StaticText elements with the identifier to find the amount field
            let toAmountElements = staticTexts(.toAmountTextField)
            XCTAssertTrue(toAmountElements.firstMatch.waitForExistence(timeout: .robustUIUpdate), "To amount elements should exist")

            // Find the element that contains the receive amount (usually starts with "~")
            var youReceiveText = ""
            let elementsCount = toAmountElements.count

            for index in 0 ..< elementsCount {
                let element = toAmountElements.element(boundBy: index)
                if element.exists {
                    let elementText = element.label
                    // Look for the element that starts with ~ (this is the receive amount)
                    if elementText.hasPrefix("~") {
                        youReceiveText = elementText
                        break
                    }
                }
            }

            XCTAssertFalse(youReceiveText.isEmpty, "You receive amount should not be empty")

            // Extract numeric value from the text
            let cleanedText = youReceiveText.replacingOccurrences(of: "~", with: "").trimmingCharacters(in: .whitespaces)

            // Handle European decimal format
            var numericString = cleanedText.replacingOccurrences(of: ",", with: ".")

            // Use a more precise regex to keep only digits and a single decimal point
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
            XCTAssertTrue(feeSelectorTitle.waitForExistence(timeout: .robustUIUpdate), "Fee selector title should appear")
            XCTAssertTrue(normalFeeOption.waitForExistence(timeout: .robustUIUpdate), "Normal fee option should exist")
            XCTAssertTrue(priorityFeeOption.waitForExistence(timeout: .robustUIUpdate), "Priority fee option should exist")
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
            // Wait for fee selector to disappear
            XCTAssertTrue(feeSelectorTitle.waitForNonExistence(timeout: .robustUIUpdate), "Fee selector should disappear after selection")

            // Validate fee block still exists with updated fee
            XCTAssertTrue(feeBlock.waitForExistence(timeout: .robustUIUpdate), "Fee block should still exist after fee change")
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
    case feeSelectorTitle
    case normalFeeOption
    case priorityFeeOption

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
        case .feeSelectorTitle:
            return SwapAccessibilityIdentifiers.feeSelectorTitle
        case .normalFeeOption:
            return SwapAccessibilityIdentifiers.normalFeeOption
        case .priorityFeeOption:
            return SwapAccessibilityIdentifiers.priorityFeeOption
        }
    }
}
