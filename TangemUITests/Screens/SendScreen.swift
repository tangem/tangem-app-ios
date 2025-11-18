//
//  SendScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendScreen: ScreenBase<SendScreenElement> {
    private lazy var titleLabel = staticText(.title)
    private lazy var amountTextField = textField(.amountTextField)
    private lazy var destinationTextView = textView(.destinationTextView)
    private lazy var addressClearButton = button(.addressClearButton)
    private lazy var nextButton = button(.nextButton)
    private lazy var backButton = button(.backButton)
    private lazy var invalidAmountBanner = staticText(.invalidAmountBanner)
    private lazy var insufficientAmountToReserveAtDestinationBanner = staticText(.insufficientAmountToReserveAtDestinationBanner)
    private lazy var amountExceedMaximumUTXOBanner = staticText(.amountExceedMaximumUTXOBanner)

    @discardableResult
    func validate() -> Self {
        XCTContext.runActivity(named: "Validate Send screen is displayed") { _ in
            XCTAssertTrue(titleLabel.waitForExistence(timeout: .robustUIUpdate), "Title should exist")
            XCTAssertTrue(amountTextField.exists, "Amount text field should exist")
            XCTAssertTrue(nextButton.exists, "Next button should exist")
        }
        return self
    }

    // MARK: - Action Methods

    @discardableResult
    func enterAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Enter amount '\(amount)' in amount field") { _ in
            amountTextField.typeText(amount)
        }
        return self
    }

    @discardableResult
    func enterDestination(_ address: String) -> Self {
        XCTContext.runActivity(named: "Enter address '\(address)' in destination field") { _ in
            destinationTextView.typeText(address)
        }
        return self
    }

    @discardableResult
    func clearDestination() -> Self {
        XCTContext.runActivity(named: "Clear destination address field") { _ in
            addressClearButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapNextButton() -> Self {
        XCTContext.runActivity(named: "Tap Next button") { _ in
            XCTAssertTrue(nextButton.isEnabled, "Next button should be enabled")
            nextButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapBackButton() -> Self {
        XCTContext.runActivity(named: "Tap Back button") { _ in
            backButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapSendButton() -> Self {
        XCTContext.runActivity(named: "Tap Send button") { _ in
            app.buttons["Send"].firstMatch.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForInvalidAmountBanner() -> Self {
        XCTContext.runActivity(named: "Validate invalid amount banner exists") { _ in
            waitAndAssertTrue(invalidAmountBanner, "Invalid amount banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForInvalidAmountBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate invalid amount banner does not exist") { _ in
            XCTAssertTrue(invalidAmountBanner.waitForNonExistence(timeout: .robustUIUpdate), "Invalid amount banner should not be displayed")
        }
        return self
    }

    @discardableResult
    func waitForInsufficientAmountToReserveAtDestinationBanner() -> Self {
        XCTContext.runActivity(named: "Validate insufficient amount to reserve at destination banner exists") { _ in
            waitAndAssertTrue(insufficientAmountToReserveAtDestinationBanner, "Insufficient amount to reserve at destination banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForInsufficientAmountToReserveAtDestinationBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate insufficient amount to reserve at destination banner does not exist") { _ in
            XCTAssertTrue(insufficientAmountToReserveAtDestinationBanner.waitForNonExistence(timeout: .robustUIUpdate), "Insufficient amount to reserve at destination banner should not be displayed")
        }
        return self
    }

    @discardableResult
    func waitForAmountExceedMaximumUTXOBanner() -> Self {
        XCTContext.runActivity(named: "Check amount exceed maximum UTXO banner exists") { _ in
            waitAndAssertTrue(amountExceedMaximumUTXOBanner, "Amount exceed maximum UTXO banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForAmountExceedMaximumUTXOBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Check amount exceed maximum UTXO banner does not exist") { _ in
            XCTAssertTrue(amountExceedMaximumUTXOBanner.waitForNonExistence(timeout: .robustUIUpdate), "Amount exceed maximum UTXO banner should not be displayed")
        }
        return self
    }

    @discardableResult
    func waitForSendButtonDisabled() -> Self {
        XCTContext.runActivity(named: "Validate Send button is disabled") { _ in
            let sendButton = app.buttons["Send"].firstMatch
            waitAndAssertTrue(sendButton, "Send button should exist")
            XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled")
        }
        return self
    }

    @discardableResult
    func waitForSendButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Validate Send button is enabled") { _ in
            let sendButton = app.buttons["Send"].firstMatch
            waitAndAssertTrue(sendButton, "Send button should exist")
            XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled")
        }
        return self
    }
}

enum SendScreenElement: String, UIElement {
    case title
    case amountTextField
    case destinationTextView
    case addressClearButton
    case nextButton
    case backButton
    case invalidAmountBanner
    case insufficientAmountToReserveAtDestinationBanner
    case amountExceedMaximumUTXOBanner

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return SendAccessibilityIdentifiers.sendViewTitle
        case .amountTextField:
            return SendAccessibilityIdentifiers.decimalNumberTextField
        case .destinationTextView:
            return SendAccessibilityIdentifiers.addressTextView
        case .addressClearButton:
            return SendAccessibilityIdentifiers.addressClearButton
        case .nextButton:
            return SendAccessibilityIdentifiers.sendViewNextButton
        case .backButton:
            return CommonUIAccessibilityIdentifiers.circleButton
        case .invalidAmountBanner:
            return SendAccessibilityIdentifiers.invalidAmountBanner
        case .insufficientAmountToReserveAtDestinationBanner:
            return SendAccessibilityIdentifiers.insufficientAmountToReserveAtDestinationBanner
        case .amountExceedMaximumUTXOBanner:
            return SendAccessibilityIdentifiers.amountExceedMaximumUTXOBanner
        }
    }
}
