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
    private lazy var stakeButton = button(.stakeButton)
    private lazy var amountValue = staticText(.amountValue)
    private lazy var validatorBlock = staticText(.validatorBlock)
    private lazy var networkFeeBlock = otherElement(.networkFeeBlock)
    private lazy var networkFeeAmount = staticText(.networkFeeAmount)
    private lazy var amountBlock = button(.amountBlock)

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
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for display: Send Summary Screen") { _ in
            XCTAssertTrue(validatorBlock.waitForExistence(timeout: .robustUIUpdate), "Validator block should be displayed")
            XCTAssertTrue(networkFeeBlock.waitForExistence(timeout: .robustUIUpdate), "Network fee block should be displayed")
            XCTAssertTrue(stakeButton.waitForExistence(timeout: .robustUIUpdate), "Stake button should exist")
            XCTAssertTrue(stakeButton.isEnabled, "Stake button should be enabled")
            XCTAssertTrue(stakeButton.label.contains("Stake"), "Stake button should have 'Stake' text")
            return self
        }
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
}

enum SendSummaryScreenElement: String, UIElement {
    case title
    case stakeButton
    case amountValue
    case validatorBlock
    case networkFeeBlock
    case networkFeeAmount
    case amountBlock

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return StakingAccessibilityIdentifiers.title
        case .stakeButton:
            return StakingAccessibilityIdentifiers.stakeButton
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
