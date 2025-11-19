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
    private lazy var networkFeeBlock = staticText(.networkFeeBlock)
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
    func tapAmountField() -> SendScreen {
        XCTContext.runActivity(named: "Tap on amount field to edit") { _ in
            waitAndAssertTrue(amountBlock, "Amount block should exist")
            amountBlock.waitAndTap()
        }
        return SendScreen(app)
    }
}

enum SendSummaryScreenElement: String, UIElement {
    case title
    case stakeButton
    case amountValue
    case validatorBlock
    case networkFeeBlock
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
        case .amountBlock:
            return SendAccessibilityIdentifiers.fromWalletButton
        }
    }
}
