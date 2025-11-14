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
    func goToSummary() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Tap Next button") { _ in
            XCTAssertTrue(nextButton.isEnabled, "Next button should be enabled")
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
        }
    }
}
