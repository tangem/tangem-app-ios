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
    private lazy var maxButton = button(.maxButton)
    private lazy var feeBlock = otherElement(.networkFeeBlock)
    private lazy var invalidAmountBanner = staticText(.invalidAmountBanner)
    private lazy var remainingAmountIsLessThanRentExemptionBanner = staticText(.remainingAmountIsLessThanRentExemptionBanner)
    private lazy var insufficientAmountToReserveAtDestinationBanner = staticText(.insufficientAmountToReserveAtDestinationBanner)
    private lazy var amountExceedMaximumUTXOBanner = otherElement(.amountExceedMaximumUTXOBanner)
    private lazy var customFeeTooLowBanner = staticText(.customFeeTooLowBanner)
    private lazy var customFeeTooHighBanner = staticText(.customFeeTooHighBanner)
    private lazy var feeWillBeSubtractFromSendingAmountBanner = staticText(.feeWillBeSubtractFromSendingAmountBanner)
    private lazy var highFeeNotificationBanner = button(.highFeeNotificationBanner)
    private lazy var existentialDepositWarningBanner = staticText(.existentialDepositWarningBanner)
    private lazy var reduceFeeButton = button(.reduceFeeButton)
    private lazy var leaveAmountButton = button(.leaveAmountButton)
    private lazy var fromWalletButton = button(.fromWalletButton)
    private lazy var networkFeeUnreachableBanner = otherElement(.networkFeeUnreachableBanner)
    private lazy var networkFeeAmount = staticText(.networkFeeAmount)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Validate Send screen is displayed") { _ in
            waitAndAssertTrue(titleLabel, "Title should exist")
            waitAndAssertTrue(amountTextField, "Amount text field should exist")
            waitAndAssertTrue(nextButton, "Next button should exist")
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
    func clearAmount() -> Self {
        XCTContext.runActivity(named: "Clear amount field") { _ in
            waitAndAssertTrue(amountTextField, "Amount text field should exist")

            let currentText = amountTextField.getValue()
            let textLength = currentText.count

            for _ in 0 ..< textLength {
                amountTextField.typeText(XCUIKeyboardKey.delete.rawValue)
            }
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
            nextButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapNextButtonToSummary() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Tap Next button to go to Summary screen") { _ in
            nextButton.waitAndTap()
        }
        return SendSummaryScreen(app)
    }

    @discardableResult
    func tapMaxButton() -> Self {
        XCTContext.runActivity(named: "Tap Max button") { _ in
            maxButton.waitAndTap()
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
    func tapFeeBlock() -> SendFeeSelectorScreen {
        XCTContext.runActivity(named: "Tap fee block on Send screen") { _ in
            let predicate = NSPredicate(format: NSPredicateFormat.labelBeginsWith.rawValue, "Network fee")
            let networkFeeButton = app.buttons.matching(predicate).firstMatch
            waitAndAssertTrue(networkFeeButton, "Network fee button should exist")
            networkFeeButton.tap()
        }
        return SendFeeSelectorScreen(app)
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
    func waitForRemainingAmountIsLessThanRentExemptionBanner() -> Self {
        XCTContext.runActivity(named: "Validate remaining amount is less than rent exemption banner exists") { _ in
            waitAndAssertTrue(remainingAmountIsLessThanRentExemptionBanner, "Remaining amount is less than rent exemption banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForRemainingAmountIsLessThanRentExemptionBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate remaining amount is less than rent exemption banner does not exist") { _ in
            XCTAssertTrue(remainingAmountIsLessThanRentExemptionBanner.waitForNonExistence(timeout: .robustUIUpdate), "Remaining amount is less than rent exemption banner should not be displayed")
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
    func waitForCustomFeeTooLowBanner() -> Self {
        XCTContext.runActivity(named: "Check custom fee too low banner exists") { _ in
            waitAndAssertTrue(customFeeTooLowBanner, "Custom fee too low banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForCustomFeeTooHighBanner() -> Self {
        XCTContext.runActivity(named: "Check custom fee too high banner exists") { _ in
            waitAndAssertTrue(customFeeTooHighBanner, "Custom fee too high banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForFeeWillBeSubtractFromSendingAmountBanner() -> Self {
        XCTContext.runActivity(named: "Check fee will be substract form sending amount banner exists") { _ in
            waitAndAssertTrue(feeWillBeSubtractFromSendingAmountBanner, "Fee will be substract form sending amount banner should be displayed")
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
            XCTAssertTrue(sendButton.waitForState(state: .enabled), "Send button should be enabled")
        }
        return self
    }

    @discardableResult
    func waitForHighFeeNotificationBanner() -> Self {
        XCTContext.runActivity(named: "Validate high fee notification banner exists") { _ in
            waitAndAssertTrue(highFeeNotificationBanner, "High fee notification banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForHighFeeNotificationBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate high fee notification banner does not exist") { _ in
            XCTAssertTrue(highFeeNotificationBanner.waitForNonExistence(timeout: .robustUIUpdate), "High fee notification banner should not be displayed")
        }
        return self
    }

    // MARK: - Network fee unreachable notification

    @discardableResult
    func waitForNetworkFeeUnreachableBanner() -> Self {
        XCTContext.runActivity(named: "Validate 'Network fee unreachable' notification is displayed") { _ in
            waitAndAssertTrue(networkFeeUnreachableBanner, "Network fee unreachable banner should be displayed")

            // Refresh button inside the banner
            let refreshButton = networkFeeUnreachableBanner.buttons[CommonUIAccessibilityIdentifiers.notificationButton]
            waitAndAssertTrue(
                refreshButton,
                "Refresh button in notification should exist"
            )
        }
        return self
    }

    @discardableResult
    func tapNotificationRefresh() -> Self {
        XCTContext.runActivity(named: "Tap 'Refresh' on notification") { _ in
            let refreshButton = networkFeeUnreachableBanner.buttons[CommonUIAccessibilityIdentifiers.notificationButton]
            refreshButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForNetworkFeeUnreachableBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate 'Network fee unreachable' notification is hidden") { _ in
            XCTAssertTrue(networkFeeUnreachableBanner.waitForNonExistence(timeout: .robustUIUpdate), "Network fee unreachable banner should disappear")
        }
        return self
    }

    @discardableResult
    func waitForExistentialDepositWarningBanner() -> Self {
        XCTContext.runActivity(named: "Validate existential deposit warning banner exists") { _ in
            waitAndAssertTrue(existentialDepositWarningBanner, "Existential deposit warning banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForExistentialDepositWarningBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate existential deposit warning banner does not exist") { _ in
            XCTAssertTrue(existentialDepositWarningBanner.waitForState(state: .notHittable), "Existential deposit warning banner should not be displayed")
        }
        return self
    }

    @discardableResult
    func reduceFee() -> Self {
        XCTContext.runActivity(named: "Tap reduce fee button") { _ in
            reduceFeeButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapLeaveAmountButton() -> Self {
        XCTContext.runActivity(named: "Tap leave amount button") { _ in
            leaveAmountButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapFromWalletButton() -> Self {
        XCTContext.runActivity(named: "Tap from wallet button") { _ in
            fromWalletButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func validateAmountDecreased(from previousAmount: Decimal) -> Self {
        XCTContext.runActivity(named: "Validate amount decreased from \(previousAmount)") { _ in
            let currentAmount = getAmountNumericValue()
            XCTAssertLessThan(currentAmount, previousAmount, "Current amount (\(currentAmount)) should be less than previous amount (\(previousAmount))")
        }
        return self
    }

    func getAmountNumericValue() -> Decimal {
        XCTContext.runActivity(named: "Get amount numeric value") { _ in
            waitAndAssertTrue(amountTextField, "Amount text field should exist")
            let amountText = amountTextField.getValue()
            XCTAssertFalse(amountText.isEmpty, "Amount should not be empty")
            return NumericValueHelper.parseNumericValue(from: amountText)
        }
    }

    func getAmountValue() -> String {
        XCTContext.runActivity(named: "Get amount value") { _ in
            waitAndAssertTrue(amountTextField, "Amount text field should exist")
            return amountTextField.getValue()
        }
    }

    @discardableResult
    func validateCurrencySymbol(_ expectedSymbol: String) -> Self {
        XCTContext.runActivity(named: "Validate currency symbol: \(expectedSymbol)") { _ in
            let currencySymbolElement = app.staticTexts[SendAccessibilityIdentifiers.currencySymbol]
            waitAndAssertTrue(currencySymbolElement, "Currency symbol element should exist")
            XCTAssertTrue(
                currencySymbolElement.label.contains(expectedSymbol),
                "Currency symbol should be '\(expectedSymbol)' but was '\(currencySymbolElement.label)'"
            )
        }
        return self
    }

    @discardableResult
    func toggleCurrency() -> Self {
        XCTContext.runActivity(named: "Toggle currency between crypto and fiat") { _ in
            let toggleButton = app.buttons[SendAccessibilityIdentifiers.currencyToggleButton]
            waitAndAssertTrue(toggleButton, "Currency toggle button should exist")
            toggleButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForCryptoAmount(_ expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Wait for crypto alternative amount: \(expectedAmount)") { _ in
            let alternativeCryptoAmount = app.staticTexts[SendAccessibilityIdentifiers.alternativeCryptoAmount]
            waitAndAssertTrue(
                alternativeCryptoAmount,
                "Alternative crypto amount element should exist"
            )

            XCTAssertEqual(
                alternativeCryptoAmount.label,
                expectedAmount,
                "Alternative crypto amount should be '\(expectedAmount)' but was '\(alternativeCryptoAmount.label)'"
            )
        }
        return self
    }

    @discardableResult
    func waitForFiatAmount(_ expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Wait for fiat alternative amount: \(expectedAmount)") { _ in
            let alternativeFiatAmount = app.staticTexts[SendAccessibilityIdentifiers.alternativeFiatAmount]
            waitAndAssertTrue(
                alternativeFiatAmount,
                "Alternative fiat amount element should exist"
            )

            XCTAssertEqual(
                alternativeFiatAmount.label,
                expectedAmount,
                "Alternative fiat amount should be '\(expectedAmount)' but was '\(alternativeFiatAmount.label)'"
            )
        }
        return self
    }

    @discardableResult
    func validateNetworkFee(_ expectedFee: String) -> Self {
        XCTContext.runActivity(named: "Validate network fee: \(expectedFee)") { _ in
            waitAndAssertTrue(networkFeeAmount)
            XCTAssertEqual(
                networkFeeAmount.label,
                expectedFee,
                "Network fee should be '\(expectedFee)' but was '\(networkFeeAmount.label)'"
            )
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
    case maxButton
    case networkFeeBlock
    case invalidAmountBanner
    case remainingAmountIsLessThanRentExemptionBanner
    case insufficientAmountToReserveAtDestinationBanner
    case amountExceedMaximumUTXOBanner
    case customFeeTooLowBanner
    case customFeeTooHighBanner
    case feeWillBeSubtractFromSendingAmountBanner
    case highFeeNotificationBanner
    case existentialDepositWarningBanner
    case reduceFeeButton
    case leaveAmountButton
    case fromWalletButton
    case networkFeeUnreachableBanner
    case networkFeeAmount

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
        case .maxButton:
            return SendAccessibilityIdentifiers.maxAmountButton
        case .networkFeeBlock:
            return SendAccessibilityIdentifiers.networkFeeBlock
        case .invalidAmountBanner:
            return SendAccessibilityIdentifiers.invalidAmountBanner
        case .remainingAmountIsLessThanRentExemptionBanner:
            return SendAccessibilityIdentifiers.remainingAmountIsLessThanRentExemptionBanner
        case .insufficientAmountToReserveAtDestinationBanner:
            return SendAccessibilityIdentifiers.insufficientAmountToReserveAtDestinationBanner
        case .amountExceedMaximumUTXOBanner:
            return SendAccessibilityIdentifiers.amountExceedMaximumUTXOBanner
        case .customFeeTooLowBanner:
            return SendAccessibilityIdentifiers.customFeeTooLowBanner
        case .customFeeTooHighBanner:
            return SendAccessibilityIdentifiers.customFeeTooHighBanner
        case .feeWillBeSubtractFromSendingAmountBanner:
            return SendAccessibilityIdentifiers.feeWillBeSubtractFromSendingAmountBanner
        case .highFeeNotificationBanner:
            return SendAccessibilityIdentifiers.highFeeNotificationBanner
        case .existentialDepositWarningBanner:
            return SendAccessibilityIdentifiers.existentialDepositWarningBanner
        case .reduceFeeButton:
            return SendAccessibilityIdentifiers.reduceFeeButton
        case .leaveAmountButton:
            return SendAccessibilityIdentifiers.leaveAmountButton
        case .fromWalletButton:
            return SendAccessibilityIdentifiers.fromWalletButton
        case .networkFeeUnreachableBanner:
            return SendAccessibilityIdentifiers.networkFeeUnreachableBanner
        case .networkFeeAmount:
            return SendAccessibilityIdentifiers.networkFeeAmount
        }
    }
}
