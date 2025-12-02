//
//  SendScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import UIKit
import TangemAccessibilityIdentifiers

final class SendScreen: ScreenBase<SendScreenElement> {
    private lazy var titleLabel = staticText(.title)
    private lazy var amountTextField = textField(.amountTextField)
    private lazy var destinationTextView = textView(.destinationTextView)
    private lazy var addressClearButton = button(.addressClearButton)
    private lazy var scanQRButton = button(.scanQRButton)
    private lazy var nextButton = button(.nextButton)
    private lazy var backButton = button(.backButton)
    private lazy var maxButton = button(.maxButton)
    private lazy var invalidAmountBanner = staticText(.invalidAmountBanner)
    private lazy var totalExceedsBalanceBanner = staticText(.totalExceedsBalanceBanner)
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
    private lazy var additionalFieldTextField = textField(.additionalFieldTextField)
    private lazy var additionalFieldClearButton = button(.additionalFieldClearButton)
    private lazy var additionalFieldPasteButton = button(.additionalFieldPasteButton)
    private lazy var invalidMemoBanner = staticText(.invalidMemoBanner)
    private lazy var addressFieldTitle = staticText(.addressFieldTitle)
    private lazy var myWalletsBlock = staticText(.myWalletsBlock)
    private lazy var pasteButton = button(.addressPasteButton)
    private lazy var networkWarningLabel = staticText(.addressNetworkWarning)
    private lazy var resolvedAddressLabel = staticText(.addressResolvedAddress)
    private lazy var closeButton = button(.closeButton)

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
    func tapDestinationField() -> Self {
        XCTContext.runActivity(named: "Tap destination field") { _ in
            destinationTextView.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapScanQRButton() -> SendQRScannerScreen {
        XCTContext.runActivity(named: "Tap Scan QR button") { _ in
            scanQRButton.waitAndTap()
        }
        return SendQRScannerScreen(app)
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
    func tapCloseButton() -> TokenScreen {
        XCTContext.runActivity(named: "Tap Close button on Send screen") { _ in
            closeButton.waitAndTap()
        }
        return TokenScreen(app)
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
    func waitForTotalExceedsBalanceBanner() -> Self {
        XCTContext.runActivity(named: "Validate 'Total exceeds balance' banner exists") { _ in
            waitAndAssertTrue(totalExceedsBalanceBanner, "'Total exceeds balance' banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForTotalExceedsBalanceBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate 'Total exceeds balance' banner does not exist") { _ in
            XCTAssertTrue(totalExceedsBalanceBanner.waitForNonExistence(timeout: .robustUIUpdate), "'Total exceeds balance' banner should not be displayed")
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
    func waitForNextButtonDisabled() -> Self {
        XCTContext.runActivity(named: "Validate Next button is disabled") { _ in
            waitAndAssertTrue(nextButton, "Next button should exist")
            XCTAssertTrue(nextButton.waitForState(state: .disabled), "Next button should be disabled")
        }
        return self
    }

    @discardableResult
    func waitForNextButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Validate Next button is enabled") { _ in
            waitAndAssertTrue(nextButton, "Next button should exist")
            XCTAssertTrue(nextButton.waitForState(state: .enabled), "Next button should be enabled")
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
    func waitForAmountValue(_ expectedAmount: String) -> Self {
        XCTContext.runActivity(named: "Validate amount value is '\(expectedAmount)'") { _ in
            waitAndAssertTrue(amountTextField, "Amount text field should exist")
            let actualAmount = amountTextField.getValue()
            XCTAssertEqual(
                actualAmount,
                expectedAmount,
                "Amount should be '\(expectedAmount)' but was '\(actualAmount)'"
            )
        }
        return self
    }

    @discardableResult
    func waitForAmountIsNotEmpty() -> Self {
        XCTContext.runActivity(named: "Validate amount field is not empty") { _ in
            waitAndAssertTrue(amountTextField, "Amount text field should exist")
            let amount = amountTextField.getValue()
            XCTAssertFalse(
                amount.isEmpty,
                "Amount field should not be empty"
            )
        }
        return self
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

    // MARK: - Additional Field (Memo/DestinationTag) Methods

    @discardableResult
    func enterAdditionalField(_ value: String) -> Self {
        XCTContext.runActivity(named: "Enter additional field value '\(value)'") { _ in
            waitAndAssertTrue(additionalFieldTextField, "Additional field text field should exist")
            additionalFieldTextField.waitAndTap()
            additionalFieldTextField.typeText(value)
        }
        return self
    }

    @discardableResult
    func pasteAdditionalField(_ value: String) -> Self {
        XCTContext.runActivity(named: "Paste additional field value '\(value)'") { _ in
            waitAndAssertTrue(additionalFieldTextField, "Additional field text field should exist")
            UIPasteboard.general.string = value
            additionalFieldPasteButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func clearAdditionalField() -> Self {
        XCTContext.runActivity(named: "Clear additional field") { _ in
            additionalFieldClearButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForInvalidMemoBanner() -> Self {
        XCTContext.runActivity(named: "Validate invalid memo banner exists") { _ in
            waitAndAssertTrue(invalidMemoBanner, "Invalid memo banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForInvalidMemoBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate invalid memo banner does not exist") { _ in
            XCTAssertTrue(invalidMemoBanner.waitForNonExistence(timeout: .robustUIUpdate), "Invalid memo banner should not be displayed")
        }
        return self
    }

    @discardableResult
    func waitForAdditionalFieldValue(_ expectedValue: String) -> Self {
        XCTContext.runActivity(named: "Validate additional field value: \(expectedValue)") { _ in
            waitAndAssertTrue(additionalFieldTextField, "Additional field text field should exist")
            let actualValue = additionalFieldTextField.getValue()
            XCTAssertEqual(
                actualValue,
                expectedValue,
                "Additional field value should be '\(expectedValue)' but was '\(actualValue)'"
            )
        }
        return self
    }

    @discardableResult
    func waitForAdditionalFieldIsEmpty() -> Self {
        XCTContext.runActivity(named: "Validate additional field is empty") { _ in
            waitAndAssertTrue(additionalFieldTextField, "Additional field text field should exist")
            let actualValue = additionalFieldTextField.getValue()
            XCTAssertTrue(
                actualValue.isEmpty,
                "Additional field should be empty but was '\(actualValue)'"
            )
        }
        return self
    }

    @discardableResult
    func waitForAdditionalFieldEnabled() -> Self {
        XCTContext.runActivity(named: "Validate additional field (destination tag) is enabled") { _ in
            waitAndAssertTrue(additionalFieldTextField, "Additional field text field should exist")
            XCTAssertTrue(
                additionalFieldTextField.isEnabled,
                "Additional field (destination tag) should be enabled"
            )
        }
        return self
    }

    @discardableResult
    func waitForAdditionalFieldDisabled() -> Self {
        XCTContext.runActivity(named: "Validate additional field (destination tag) is disabled") { _ in
            waitAndAssertTrue(additionalFieldTextField, "Additional field text field should exist")
            XCTAssertFalse(
                additionalFieldTextField.isEnabled,
                "Additional field (destination tag) should be disabled"
            )
        }
        return self
    }

    @discardableResult
    func waitForAlreadyIncludedText() -> Self {
        XCTContext.runActivity(named: "Validate 'Already included in the entered address' text is displayed") { _ in
            waitAndAssertTrue(additionalFieldTextField, "Additional field text field should exist")
            let alreadyIncludedText = "Already included in the entered address"
            let placeholderValue = additionalFieldTextField.placeholderValue

            XCTAssertEqual(
                placeholderValue,
                alreadyIncludedText,
                "Text 'Already included in the entered address' should be displayed in additional field"
            )
        }
        return self
    }

    @discardableResult
    func waitForAddressSameAsWalletText() -> Self {
        XCTContext.runActivity(named: "Validate 'Address is the same as wallet address' text is displayed") { _ in
            waitAndAssertTrue(addressFieldTitle, "Address same as wallet error text should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForInvalidAddressText() -> Self {
        XCTContext.runActivity(named: "Validate 'Not a valid address' error is displayed") { _ in
            waitAndAssertTrue(addressFieldTitle, "Not a valid address")
        }
        return self
    }

    // MARK: - ENS Address Methods

    @discardableResult
    func waitForResolvedAddressDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate resolved address is displayed under ENS domain") { _ in
            waitAndAssertTrue(resolvedAddressLabel, "Resolved address should be displayed under ENS domain")
        }
        return self
    }

    @discardableResult
    func waitForResolvedAddressNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate resolved address is not displayed") { _ in
            XCTAssertTrue(
                resolvedAddressLabel.waitForNonExistence(timeout: .robustUIUpdate),
                "Resolved address should not be displayed"
            )
        }
        return self
    }

    @discardableResult
    func waitForResolvedAddressContains(_ address: String) -> Self {
        XCTContext.runActivity(named: "Validate resolved address contains '\(address)'") { _ in
            waitAndAssertTrue(resolvedAddressLabel, "Resolved address label should exist")
            XCTAssertTrue(
                resolvedAddressLabel.label.contains(address),
                "Resolved address should contain '\(address)' but was '\(resolvedAddressLabel.label)'"
            )
        }
        return self
    }

    // MARK: - Destination Field Methods

    @discardableResult
    func pasteDestination(_ address: String) -> Self {
        XCTContext.runActivity(named: "Paste address '\(address)' via Paste button") { _ in
            UIPasteboard.general.string = address
            pasteButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForInvalidAddressErrorNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate 'Not a valid address' error is not displayed") { _ in
            let predicate = NSPredicate(format: "label CONTAINS[cd] %@", "Not a valid address")
            let errorText = app.staticTexts.matching(predicate).firstMatch
            XCTAssertTrue(
                errorText.waitForNonExistence(timeout: .robustUIUpdate),
                "'Not a valid address' error should not be displayed"
            )
        }
        return self
    }

    func getDestinationValue() -> String {
        XCTContext.runActivity(named: "Get destination address value") { _ in
            waitAndAssertTrue(destinationTextView, "Destination text view should exist")
            return destinationTextView.getValue()
        }
    }

    @discardableResult
    func waitForDestinationValue(_ expectedValue: String) -> Self {
        XCTContext.runActivity(named: "Validate destination value: \(expectedValue)") { _ in
            waitAndAssertTrue(destinationTextView, "Destination text view should exist")
            let actualValue = destinationTextView.getValue()
            XCTAssertEqual(
                actualValue,
                expectedValue,
                "Destination value should be '\(expectedValue)' but was '\(actualValue)'"
            )
        }
        return self
    }

    @discardableResult
    func validateDestinationIsEmpty() -> Self {
        XCTContext.runActivity(named: "Validate destination field is empty") { _ in
            waitAndAssertTrue(destinationTextView, "Destination text view should exist")
            let actualValue = destinationTextView.getValue()
            XCTAssertTrue(
                actualValue.isEmpty,
                "Destination field should be empty but was '\(actualValue)'"
            )
        }
        return self
    }

    @discardableResult
    func waitForAddressScreenElements() -> Self {
        XCTContext.runActivity(named: "Validate address screen UI elements") { _ in
            waitAndAssertTrue(titleLabel, "Address screen title should exist")
            waitAndAssertTrue(addressFieldTitle, "Recipient field title should exist")
            waitAndAssertTrue(destinationTextView, "Destination field should exist")
            waitAndAssertTrue(scanQRButton, "Scan QR button should exist")
            waitAndAssertTrue(pasteButton, "Paste button should exist")
            waitAndAssertTrue(networkWarningLabel, "Network warning text should exist")
        }
        return self
    }

    // MARK: - Wallet History Methods

    func getWalletHistoryCell(at index: Int) -> XCUIElement {
        XCTContext.runActivity(named: "Get wallet history cell at index \(index)") { _ in
            let identifier = SendAccessibilityIdentifiers.suggestedDestinationWalletCell(index: index)
            let cell = app.staticTexts[identifier].firstMatch

            guard cell.waitForExistence(timeout: .robustUIUpdate) else {
                XCTFail("Wallet cell at index \(index) does not exist")
                return app.staticTexts.firstMatch
            }

            return cell
        }
    }

    func getTransactionHistoryCell(at index: Int) -> XCUIElement {
        XCTContext.runActivity(named: "Get transaction history cell at index \(index)") { _ in
            let identifier = SendAccessibilityIdentifiers.suggestedDestinationTransactionCell(index: index)
            let cell = app.staticTexts[identifier].firstMatch

            guard cell.waitForExistence(timeout: .robustUIUpdate) else {
                XCTFail("Transaction cell at index \(index) does not exist")
                return app.staticTexts.firstMatch
            }

            return cell
        }
    }

    func getAddressFromWalletCell(at index: Int) -> String {
        XCTContext.runActivity(named: "Get address from wallet cell at index \(index)") { _ in
            let cell = getWalletHistoryCell(at: index)
            waitAndAssertTrue(cell, "Wallet cell at index \(index) should exist")

            let address = cell.label
            guard !address.isEmpty else {
                XCTFail("Could not extract address from wallet cell at index \(index)")
                return ""
            }

            return address
        }
    }

    func getAddressFromTransactionCell(at index: Int) -> String {
        XCTContext.runActivity(named: "Get address from transaction cell at index \(index)") { _ in
            let cell = getTransactionHistoryCell(at: index)
            waitAndAssertTrue(cell, "Transaction cell at index \(index) should exist")

            let address = cell.label
            guard !address.isEmpty else {
                XCTFail("Could not extract address from transaction cell at index \(index)")
                return ""
            }

            return address
        }
    }

    @discardableResult
    func selectWalletCell(at index: Int) -> Self {
        XCTContext.runActivity(named: "Select wallet cell at index \(index)") { _ in
            let cell = getWalletHistoryCell(at: index)
            cell.waitAndTap()
        }
        return self
    }

    @discardableResult
    func selectTransactionCell(at index: Int) -> Self {
        XCTContext.runActivity(named: "Select transaction cell at index \(index)") { _ in
            let cell = getTransactionHistoryCell(at: index)
            cell.waitAndTap()
        }
        return self
    }

    func selectFirstAvailableHistoryCell() -> String {
        XCTContext.runActivity(named: "Select first available history cell") { _ in
            // Try wallet cells first
            let firstWalletIdentifier = SendAccessibilityIdentifiers.suggestedDestinationWalletCell(index: 0)
            let firstWalletCell = app.staticTexts[firstWalletIdentifier].firstMatch

            if firstWalletCell.waitForExistence(timeout: .robustUIUpdate) {
                let address = getAddressFromWalletCell(at: 0)
                selectWalletCell(at: 0)
                return address
            }

            // Try transaction cells
            let firstTransactionIdentifier = SendAccessibilityIdentifiers.suggestedDestinationTransactionCell(index: 0)
            let firstTransactionCell = app.staticTexts[firstTransactionIdentifier].firstMatch

            if firstTransactionCell.waitForExistence(timeout: .robustUIUpdate) {
                let address = getAddressFromTransactionCell(at: 0)
                selectTransactionCell(at: 0)
                return address
            }

            XCTFail("No history cells available")
            return ""
        }
    }

    @discardableResult
    func selectAddressFromHistory(_ address: String) -> Self {
        XCTContext.runActivity(named: "Select address '\(address)' from wallet history") { _ in
            // Search by address text in wallet cells
            let walletCellPredicate = NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@", "sendSuggestedDestinationWalletCell_", address)
            let walletCell = app.staticTexts.matching(walletCellPredicate).firstMatch

            if walletCell.waitForExistence(timeout: .robustUIUpdate) {
                walletCell.waitAndTap()
                return
            }

            // Search by address text in transaction cells
            let transactionCellPredicate = NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@", "sendSuggestedDestinationTransactionCell_", address)
            let transactionCell = app.staticTexts.matching(transactionCellPredicate).firstMatch

            if transactionCell.waitForExistence(timeout: .robustUIUpdate) {
                transactionCell.waitAndTap()
                return
            }

            // Last resort: search by address text (partial match)
            let addressPredicate = NSPredicate(format: "label CONTAINS[cd] %@", address)
            let addressElement = app.staticTexts.matching(addressPredicate).firstMatch
            waitAndAssertTrue(addressElement, "Address '\(address)' should exist in history")
            addressElement.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForWalletHistoryDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate wallet history is displayed") { _ in
            // Check for header using accessibility identifier
            let header = app.staticTexts[SendAccessibilityIdentifiers.suggestedDestinationHeader].firstMatch

            // Also check for any wallet or transaction cell (identifier is on the address text)
            let walletCellPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSuggestedDestinationWalletCell_")
            let transactionCellPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSuggestedDestinationTransactionCell_")
            let walletCell = app.staticTexts.matching(walletCellPredicate).firstMatch
            let transactionCell = app.staticTexts.matching(transactionCellPredicate).firstMatch

            XCTAssertTrue(
                header.waitForExistence(timeout: .robustUIUpdate) ||
                    walletCell.waitForExistence(timeout: .robustUIUpdate) ||
                    transactionCell.waitForExistence(timeout: .robustUIUpdate),
                "Wallet history should be displayed"
            )
        }
        return self
    }

    @discardableResult
    func waitForMyWalletsBlockDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate 'My Wallets' block is displayed") { _ in
            waitAndAssertTrue(myWalletsBlock, "'My Wallets' block should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForWalletHistoryNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate wallet history is not displayed") { _ in
            let header = app.staticTexts[SendAccessibilityIdentifiers.suggestedDestinationHeader].firstMatch

            XCTAssertTrue(
                header.waitForNonExistence(timeout: .robustUIUpdate),
                "Wallet history should not be displayed"
            )
        }
        return self
    }

    @discardableResult
    func waitForTransactionHistoryNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate transaction history (Recent) block is not displayed") { _ in
            // Check that transaction cells do not exist
            let transactionCellPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSuggestedDestinationTransactionCell_")
            let transactionCells = app.staticTexts.matching(transactionCellPredicate)

            // Wait for transaction cells to not exist
            let firstTransactionCell = transactionCells.firstMatch
            XCTAssertTrue(
                firstTransactionCell.waitForNonExistence(timeout: .robustUIUpdate),
                "Transaction history (Recent) block should not be displayed"
            )
        }
        return self
    }

    @discardableResult
    func waitForRecentHeaderDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate 'Recent' header is displayed") { _ in
            let headerPredicate = NSPredicate(format: "identifier == %@", SendAccessibilityIdentifiers.suggestedDestinationHeader)
            let headers = app.staticTexts.matching(headerPredicate)
            let recentHeader = headers.matching(NSPredicate(format: "label CONTAINS[cd] %@", "Recent")).firstMatch

            XCTAssertTrue(
                recentHeader.waitForExistence(timeout: .robustUIUpdate),
                "'Recent' header should be displayed"
            )
        }
        return self
    }

    func getTransactionHistoryCount() -> Int {
        XCTContext.runActivity(named: "Get transaction history count") { _ in
            let transactionCellPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSuggestedDestinationTransactionCell_")
            let transactionCells = app.staticTexts.matching(transactionCellPredicate)

            // Wait a bit for cells to load
            let firstCell = transactionCells.firstMatch
            if firstCell.waitForExistence(timeout: .robustUIUpdate) {
                return transactionCells.count
            }

            return 0
        }
    }

    @discardableResult
    func validateTransactionHistoryCount(maxCount: Int = 10) -> Self {
        XCTContext.runActivity(named: "Validate transaction history count is at most \(maxCount)") { _ in
            let count = getTransactionHistoryCount()
            XCTAssertTrue(
                count <= maxCount,
                "Transaction history should display at most \(maxCount) transactions, but found \(count)"
            )
            XCTAssertTrue(
                count > 0,
                "Transaction history should display at least 1 transaction"
            )
        }
        return self
    }

    @discardableResult
    func waitForTransactionCellHasElements(at index: Int) -> Self {
        XCTContext.runActivity(named: "Validate transaction cell at index \(index) has required elements") { _ in
            let cell = getTransactionHistoryCell(at: index)
            waitAndAssertTrue(cell, "Transaction cell at index \(index) should exist")

            let address = cell.label

            // Validate address is not empty
            XCTAssertFalse(
                address.isEmpty,
                "Transaction cell at index \(index) should have an address"
            )
        }
        return self
    }

    @discardableResult
    func waitForMyWalletsBlockNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate 'My Wallets' block is not displayed") { _ in
            XCTAssertTrue(
                myWalletsBlock.waitForNonExistence(timeout: .robustUIUpdate),
                "'My Wallets' block should not be displayed"
            )
        }
        return self
    }

    @discardableResult
    func waitForWalletAddress(_ expectedAddress: String, at index: Int = 0) -> Self {
        XCTContext.runActivity(named: "Validate wallet cell \(index) displays address '\(expectedAddress)'") { _ in
            let walletCell = getWalletHistoryCell(at: index)
            waitAndAssertTrue(walletCell, "Wallet cell at index \(index) should exist")

            XCTAssertEqual(
                walletCell.label,
                expectedAddress,
                "Wallet cell at index \(index) should display the expected address"
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
    case scanQRButton
    case nextButton
    case backButton
    case maxButton
    case networkFeeBlock
    case invalidAmountBanner
    case totalExceedsBalanceBanner
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
    case additionalFieldTextField
    case additionalFieldClearButton
    case additionalFieldPasteButton
    case invalidMemoBanner
    case addressFieldTitle
    case myWalletsBlock
    case addressPasteButton
    case addressNetworkWarning
    case addressResolvedAddress
    case closeButton

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
        case .scanQRButton:
            return SendAccessibilityIdentifiers.scanQRButton
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
        case .totalExceedsBalanceBanner:
            return SendAccessibilityIdentifiers.totalExceedsBalanceBanner
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
        case .additionalFieldTextField:
            return SendAccessibilityIdentifiers.additionalFieldTextField
        case .additionalFieldClearButton:
            return SendAccessibilityIdentifiers.additionalFieldClearButton
        case .additionalFieldPasteButton:
            return SendAccessibilityIdentifiers.additionalFieldPasteButton
        case .invalidMemoBanner:
            return SendAccessibilityIdentifiers.invalidMemoBanner
        case .addressFieldTitle:
            return SendAccessibilityIdentifiers.addressFieldTitle
        case .myWalletsBlock:
            return SendAccessibilityIdentifiers.suggestedDestinationMyWalletsBlock
        case .addressPasteButton:
            return SendAccessibilityIdentifiers.addressPasteButton
        case .addressNetworkWarning:
            return SendAccessibilityIdentifiers.addressNetworkWarning
        case .addressResolvedAddress:
            return SendAccessibilityIdentifiers.addressResolvedAddress
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        }
    }
}
