//
//  SendSummaryScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendSummaryScreen: ScreenBase<SendSummaryScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var finishButton = button(.finishButton)
    // HoldToConfirmButton (hot wallet) is not a native Button, XCUITest sees it as otherElement
    private lazy var holdFinishButton = otherElement(.finishButton)
    private lazy var amountValue = staticText(.amountValue)
    private lazy var validatorBlock = staticText(.validatorBlock)
    private lazy var networkFeeBlock = otherElement(.networkFeeBlock)
    private lazy var networkFeeAmount = staticText(.networkFeeAmount)
    private lazy var amountBlock = button(.amountBlock)

    /// Returns the active finish/send button regardless of type (regular Button or HoldToConfirmButton)
    private var activeFinishButton: XCUIElement {
        finishButton.exists ? finishButton : holdFinishButton
    }

    @discardableResult
    func waitForAmountValue(_ expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Validate amount value: \(expectedAmount)") { _ in
            waitAndAssertTrue(amountValue, "Amount value element should exist")

            let predicate = NSPredicate(format: "label CONTAINS %@", expectedAmount)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: amountValue)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Amount value should eventually contain '\(expectedAmount)'"
            )
        }
        return self
    }

    @discardableResult
    func waitForDisplay(checkValidatorBlock: Bool = true) -> Self {
        XCTContext.runActivity(named: "Wait for display: Send Summary Screen") { _ in
            waitAndAssertTrue(title, "Title should exists")

            // Check for either regular Button or HoldToConfirmButton (hot wallet)
            let buttonFound = finishButton.waitForExistence(timeout: .quick) || holdFinishButton.waitForExistence(timeout: .robustUIUpdate)
            XCTAssertTrue(buttonFound, "Finish flow button should exists")

            XCTAssertTrue(networkFeeBlock.exists, "Network fee block should be displayed")

            if checkValidatorBlock {
                XCTAssertTrue(validatorBlock.exists, "Validator block should be displayed")
            }
            return self
        }
    }

    @discardableResult
    func tapSendButton() -> SendFinishScreen {
        XCTContext.runActivity(named: "Tap Send button on Summary screen") { _ in
            if finishButton.exists {
                finishButton.waitAndTap()
            } else {
                // HoldToConfirmButton requires a long press (1.5s hold duration)
                waitAndAssertTrue(holdFinishButton, "Hold-to-confirm button should exist")
                holdFinishButton.press(forDuration: 2.0)
            }
        }
        return SendFinishScreen(app)
    }

    // MARK: - Amount Validation Methods

    @discardableResult
    func validateCryptoAmount(_ expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Validate crypto amount: \(expectedAmount)") { _ in
            waitAndAssertTrue(amountValue, "Amount value element should exist")

            let predicate = NSPredicate(format: "label CONTAINS %@", expectedAmount)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: amountValue)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Crypto amount should contain '\(expectedAmount)'"
            )
        }
        return self
    }

    @discardableResult
    func validateFiatAmount(_ expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Validate fiat amount: \(expectedAmount)") { _ in
            waitAndAssertTrue(amountBlock, "Amount block should exist")

            let predicate = NSPredicate(format: "label CONTAINS %@", expectedAmount)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: amountBlock)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Fiat amount should contain '\(expectedAmount)'"
            )
        }
        return self
    }

    @discardableResult
    func waitForNetworkFeeSelectorUnavailable() -> Self {
        XCTContext.runActivity(named: "Validate network fee selector is unavailable") { _ in
            waitAndAssertTrue(networkFeeBlock, "Network fee block should exist")
            networkFeeBlock.waitAndTap()

            let feeSelectorDoneButton = app.buttons[FeeAccessibilityIdentifiers.feeSelectorDoneButton]
            XCTAssertTrue(
                feeSelectorDoneButton.waitForNonExistence(timeout: .robustUIUpdate),
                "Fee selector should not be displayed for fixed-fee networks"
            )
        }
        return self
    }

    @discardableResult
    func tapAmountField() -> SendScreen {
        XCTContext.runActivity(named: "Tap on amount field to edit") { _ in
            waitAndAssertTrue(amountBlock, "Amount block should exist")
            amountBlock.waitAndTap()
        }
        return SendScreen(app)
    }

    // MARK: - Swap Provider Methods

    @discardableResult
    func tapProviderBlock() -> SendSwapProviderSelectorScreen {
        XCTContext.runActivity(named: "Tap provider block to open selector") { _ in
            let providerBlock = app.buttons[SendAccessibilityIdentifiers.swapProviderBlock].firstMatch
            waitAndAssertTrue(providerBlock, "Swap provider block should exist")
            providerBlock.waitAndTap()
        }
        return SendSwapProviderSelectorScreen(app)
    }

    func getProviderName() -> String {
        XCTContext.runActivity(named: "Get current provider name") { _ in
            let providerName = app.staticTexts[SendAccessibilityIdentifiers.swapProviderName].firstMatch
            waitAndAssertTrue(providerName, "Swap provider name element should exist")
            return providerName.label.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    @discardableResult
    func assertProviderName(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Assert provider name is '\(expected)'") { _ in
            let providerName = app.staticTexts[SendAccessibilityIdentifiers.swapProviderName].firstMatch
            waitAndAssertTrue(providerName, "Swap provider name element should exist")

            let predicate = NSPredicate(format: "label == %@", expected)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: providerName)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Provider name should be '\(expected)' but was '\(providerName.label)'"
            )
        }
        return self
    }

    @discardableResult
    func assertBestRateBadgeOnProvider() -> Self {
        XCTContext.runActivity(named: "Assert 'Best rate' badge is present on summary provider") { _ in
            // Badge can be Image (animated icon on summary) or Other (text badge in selector)
            let badge = app.descendants(matching: .any)[SendAccessibilityIdentifiers.swapProviderBestRateBadge].firstMatch
            waitAndAssertTrue(badge, "'Best rate' badge should be present on summary provider")
        }
        return self
    }

    @discardableResult
    func assertBestRateBadgeNotOnProvider() -> Self {
        XCTContext.runActivity(named: "Assert 'Best rate' badge is NOT present on summary provider") { _ in
            let badge = app.descendants(matching: .any)[SendAccessibilityIdentifiers.swapProviderBestRateBadge].firstMatch
            XCTAssertTrue(
                badge.waitForNonExistence(timeout: .quick),
                "'Best rate' badge should not be present on summary provider"
            )
        }
        return self
    }

    func getNetworkFeeValue() -> String {
        XCTContext.runActivity(named: "Get network fee value") { _ in
            waitAndAssertTrue(networkFeeAmount, "Network fee amount element should exist")
            return networkFeeAmount.label.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    @discardableResult
    func assertNetworkFeeChanged(from previousFee: String) -> Self {
        XCTContext.runActivity(named: "Assert network fee changed from '\(previousFee)'") { _ in
            waitAndAssertTrue(networkFeeAmount, "Network fee amount element should exist")
            let currentFee = networkFeeAmount.label.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertNotEqual(currentFee, previousFee, "Network fee should have changed")
        }
        return self
    }

    @discardableResult
    func tapFeeBlock() -> SendFeeSelectorScreen {
        XCTContext.runActivity(named: "Tap fee block on Send screen") { _ in
            waitAndAssertTrue(networkFeeBlock, "Network fee button should exist")
            networkFeeBlock.waitAndTap()
        }
        return SendFeeSelectorScreen(app)
    }

    @discardableResult
    func waitForNetworkFeeAmount(_ expectedFiatAmount: String) -> Self {
        XCTContext.runActivity(named: "Validate network fee amount matches expected fiat value: \(expectedFiatAmount)") { _ in
            waitAndAssertTrue(networkFeeAmount, "Network fee amount element should exist")

            let actualAmount = networkFeeAmount.label.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertEqual(
                actualAmount,
                expectedFiatAmount,
                "Network fee amount should be '\(expectedFiatAmount)' but was '\(actualAmount)'"
            )
        }
        return self
    }

    @discardableResult
    func verifyNetworkFeeContains(_ currencySymbol: String) -> Self {
        XCTContext.runActivity(named: "Verify network fee contains currency symbol: \(currencySymbol)") { _ in
            waitAndAssertTrue(networkFeeAmount, "Network fee amount element should exist")

            let feeLabel = networkFeeAmount.label
            XCTAssertTrue(
                feeLabel.contains(currencySymbol),
                "Network fee should contain currency symbol '\(currencySymbol)' but was '\(feeLabel)'"
            )
        }
        return self
    }
}

enum SendSummaryScreenElement: String, UIElement {
    case title
    case finishButton
    case amountValue
    case validatorBlock
    case networkFeeBlock
    case networkFeeAmount
    case amountBlock

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return SendAccessibilityIdentifiers.sendViewTitle
        case .finishButton:
            return SendAccessibilityIdentifiers.sendViewNextButton
        case .amountValue:
            return SendAccessibilityIdentifiers.sendAmountViewValue
        case .validatorBlock:
            return SendAccessibilityIdentifiers.validatorBlock
        case .networkFeeBlock:
            return SendAccessibilityIdentifiers.networkFeeBlock
        case .networkFeeAmount:
            return SendAccessibilityIdentifiers.networkFeeAmount
        case .amountBlock:
            return SendAccessibilityIdentifiers.fromWalletButton
        }
    }
}
