//
//  StakingSendScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StakingSendScreen: ScreenBase<StakingSendScreenElement> {
    private lazy var titleLabel = staticText(.title)
    private lazy var amountTextField = textField(.amountTextField)
    private lazy var nextButton = button(.nextButton)
    private lazy var balanceLabel = staticText(.balanceLabel)
    private lazy var maxButton = button(.maxButton)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Validate Send screen is displayed") { _ in
            XCTAssertTrue(titleLabel.waitForExistence(timeout: .robustUIUpdate), "Title should exist")
            XCTAssertTrue(amountTextField.exists, "Amount text field should exist")
            XCTAssertTrue(nextButton.exists, "Next button should exist")
            XCTAssertTrue(balanceLabel.exists, "Balance label should exist")
        }
        return self
    }

    // MARK: - Action Methods

    @discardableResult
    func enterStakingAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Enter amount '\(amount)' in amount field") { _ in
            amountTextField.waitAndTap()
            amountTextField.typeText(amount)
        }
        return self
    }

    @discardableResult
    func replaceStakingAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Replace prefilled amount with '\(amount)'") { _ in
            waitAndAssertTrue(amountTextField, "Amount text field should exist")
            amountTextField.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
            let currentValue = amountTextField.value as? String ?? ""
            let deletions = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            amountTextField.typeText(deletions)
            amountTextField.typeText(amount)
        }
        return self
    }

    @discardableResult
    func tapMaxAmount() -> Self {
        XCTContext.runActivity(named: "Tap Max to fill the full amount") { _ in
            maxButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func assertMaxButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Assert Max button exists and is enabled") { _ in
            XCTAssertTrue(maxButton.waitForExistence(timeout: .robustUIUpdate), "Max button should exist")
            XCTAssertTrue(maxButton.waitForState(state: .enabled), "Max button should be enabled")
        }
        return self
    }

    @discardableResult
    func goToSummary() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Tap Next button") { _ in
            XCTAssertTrue(nextButton.waitForState(state: .enabled), "Next button should be enabled")
            nextButton.waitAndTap()
        }
        return SendSummaryScreen(app)
    }

    // MARK: - Helper Methods

    func getBalanceText() -> String {
        return balanceLabel.waitForExistence(timeout: .robustUIUpdate) ? balanceLabel.label : ""
    }
}

enum StakingSendScreenElement: String, UIElement {
    case title
    case amountTextField
    case nextButton
    case balanceLabel
    case maxButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return SendAccessibilityIdentifiers.sendViewTitle
        case .amountTextField:
            return SendAccessibilityIdentifiers.decimalNumberTextField
        case .nextButton:
            return SendAccessibilityIdentifiers.sendViewNextButton
        case .balanceLabel:
            return SendAccessibilityIdentifiers.balanceLabel
        case .maxButton:
            return SendAccessibilityIdentifiers.maxAmountButton
        }
    }
}
