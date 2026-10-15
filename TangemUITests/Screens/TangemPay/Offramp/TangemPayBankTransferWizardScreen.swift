//
//  TangemPayBankTransferWizardScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayBankTransferWizardScreen: ScreenBase<TangemPayBankTransferWizardScreenElement> {
    private lazy var transferTypeContinueButton = button(.transferTypeContinueButton)
    private lazy var accountTypeContinueButton = button(.accountTypeContinueButton)
    private lazy var formContinueButton = button(.formContinueButton)
    private lazy var keyboardDismissButton = button(.keyboardDismissButton)

    @discardableResult
    func verifyTransferTypeNothingSelected() -> Self {
        XCTContext.runActivity(named: "Verify no transfer type is preselected") { _ in
            for type in [TransferType.ownAccount, .thirdPartyAccount] {
                let element = option(.transferTypeOption, label: type.title)
                waitAndAssertTrue(element, timeout: .networkRequest, "'\(type.title)' option should be displayed")
                XCTAssertFalse(element.isSelected, "'\(type.title)' should not be preselected")
            }
            XCTAssertFalse(transferTypeContinueButton.isEnabled, "Continue should stay disabled until a transfer type is chosen")
            return self
        }
    }

    @discardableResult
    func selectTransferType(_ type: TransferType) -> Self {
        XCTContext.runActivity(named: "Select transfer type '\(type.title)'") { _ in
            option(.transferTypeOption, label: type.title).waitAndTap(timeout: .networkRequest)
            transferTypeContinueButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func selectAccountType(_ type: AccountType) -> Self {
        XCTContext.runActivity(named: "Select account type '\(type.title)'") { _ in
            option(.accountTypeOption, label: type.title).waitAndTap(timeout: .networkRequest)
            accountTypeContinueButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func fillRecipientDetails(_ details: RecipientDetails) -> Self {
        XCTContext.runActivity(named: "Fill in the recipient details of \(details.name.fullName)") { _ in
            waitForRecipientDetailsForm()
            enter(details.accountNumber, into: .accountNumber)
            enter(details.routingNumber, into: .routingNumber)
            switch details.name {
            case .individual(let firstName, let lastName):
                enter(firstName, into: .firstName)
                enter(lastName, into: .lastName)
            case .business(let businessName):
                enter(businessName, into: .businessName)
            }
            if !isLocationSelected(country: details.country, region: details.region) {
                selectCountry(details.country, region: details.region)
            }
            enter(details.city, into: .city)
            enter(details.addressLine1, into: .line1)
            enter(details.postalCode, into: .postalCode)
            tapFormContinue()
            return self
        }
    }

    @discardableResult
    func fillBankDetails(_ details: BankDetails) -> TangemPayBankTransferConfirmScreen {
        XCTContext.runActivity(named: "Fill in the bank details of \(details.name)") { _ in
            waitForBankDetailsForm()
            enter(details.name, into: .bankName)
            selectOption(details.region, from: .bankRegion)
            enter(details.city, into: .bankCity)
            enter(details.addressLine1, into: .bankLine1)
            enter(details.postalCode, into: .bankPostalCode)
            tapFormContinue()
            return TangemPayBankTransferConfirmScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func waitForRecipientDetailsForm() -> Self {
        XCTContext.runActivity(named: "Wait for the recipient details form") { _ in
            waitAndAssertTrue(field(.accountNumber), timeout: .networkRequest, "Recipient details form should be displayed")
            return self
        }
    }

    @discardableResult
    func waitForBankDetailsForm() -> Self {
        XCTContext.runActivity(named: "Wait for the bank details form") { _ in
            waitAndAssertTrue(field(.bankName), timeout: .networkRequest, "Bank details form should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyFieldValue(_ formField: FormField, _ value: String) -> Self {
        XCTContext.runActivity(named: "Verify \(formField.rawValue) reads '\(value)'") { _ in
            let element = field(formField)
            waitAndAssertTrue(element, timeout: .networkRequest, "\(formField.rawValue) field should be displayed")
            XCTAssertTrue(
                element.waitForValue(where: { $0 == value }),
                "\(formField.rawValue) should read '\(value)'. Actual: '\(element.getValue())'"
            )
            return self
        }
    }

    @discardableResult
    func replaceText(in formField: FormField, with text: String) -> Self {
        XCTContext.runActivity(named: "Replace \(formField.rawValue) with '\(text)'") { _ in
            enter(text, into: formField)
            dismissKeyboard()
            return self
        }
    }

    @discardableResult
    func verifyFieldError(_ formField: FormField, _ message: String) -> Self {
        XCTContext.runActivity(named: "Verify \(formField.rawValue) shows '\(message)'") { _ in
            let error = fieldError(formField)
            assertPresent(error, "\(formField.rawValue) should show an error")
            XCTAssertEqual(error.label, message, "\(formField.rawValue) error should read '\(message)'")
            return self
        }
    }

    @discardableResult
    func verifyNoFieldError(_ formField: FormField) -> Self {
        XCTContext.runActivity(named: "Verify \(formField.rawValue) shows no error") { _ in
            let error = fieldError(formField)
            XCTAssertTrue(
                !error.exists || error.waitForNonExistence(timeout: .conditional),
                "\(formField.rawValue) should not show an error. Actual: '\(fieldError(formField).label)'"
            )
            return self
        }
    }

    @discardableResult
    func selectCountry(_ country: String, region: String? = nil) -> Self {
        XCTContext.runActivity(named: "Select \(country)\(region.map { ", \($0)" } ?? "")") { _ in
            selectOption(country, from: .countryCode)
            if let region {
                TangemPayGeoSelectionScreen(app).selectRow(region)
            }
            XCTAssertTrue(
                field(.countryCode).waitForValue(where: { $0.contains(country) }),
                "Country should read '\(country)'. Actual: '\(field(.countryCode).getValue())'"
            )
            return self
        }
    }

    @discardableResult
    func tapContinueToBankDetails() -> Self {
        tapFormContinue()
        return waitForBankDetailsForm()
    }

    @discardableResult
    func tapContinueToConfirmation() -> TangemPayBankTransferConfirmScreen {
        tapFormContinue()
        return TangemPayBankTransferConfirmScreen(app).waitForScreen()
    }

    @discardableResult
    func close() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the bank transfer") { _ in
            dismissKeyboard()
            guard let closeButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonClose)).firstHittableElement() else {
                XCTFail("Bank transfer Close button should become hittable")
                return TangemPayMainScreen(app)
            }
            closeButton.tap()
            return TangemPayMainScreen(app).waitForScreen()
        }
    }

    private func selectOption(_ option: String, from formField: FormField) {
        dismissKeyboard()
        let element = field(formField)
        waitAndAssertTrue(element, "\(formField.rawValue) field should be displayed")
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        TangemPayGeoSelectionScreen(app).selectRow(option)
    }

    private func enter(_ text: String, into formField: FormField) {
        let element = field(formField)
        assertPresent(element, "\(formField.rawValue) field should be displayed")
        let currentText = hasText(element) ? element.getValue() : ""
        guard currentText != text else { return }
        if isCoveredByKeyboard(element) {
            dismissKeyboard()
        }
        element.tap()
        if !currentText.isEmpty {
            element.coordinate(withNormalizedOffset: Constants.textEndOffset).tap()
        }
        element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count) + text)
        XCTAssertTrue(
            element.getValue() == text || element.waitForValue(where: { $0 == text }),
            "\(formField.rawValue) should read '\(text)'. Actual: '\(element.getValue())'"
        )
    }

    private func tapFormContinue() {
        XCTContext.runActivity(named: "Tap Continue on the form") { _ in
            dismissKeyboard()
            XCTAssertTrue(formContinueButton.waitForState(state: .enabled, for: .conditional), "Continue should be enabled once the form is filled")
            formContinueButton.waitAndTap()
        }
    }

    private func dismissKeyboard() {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return }
        if keyboardDismissButton.exists {
            keyboardDismissButton.tap()
        } else {
            keyboardDismissButton.waitAndTap()
        }
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: .conditional), "Keyboard should be dismissed")
    }

    private func isLocationSelected(country: String, region: String) -> Bool {
        let regionField = field(.region)
        return field(.countryCode).getValue() == country && regionField.exists && regionField.getValue() == region
    }

    private func isCoveredByKeyboard(_ element: XCUIElement) -> Bool {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return false }
        let keyboardTop = keyboardDismissButton.exists ? keyboardDismissButton.frame.minY : keyboard.frame.minY
        return element.frame.maxY > keyboardTop - Constants.keyboardTopInset
    }

    private func assertPresent(_ element: XCUIElement, _ message: String) {
        guard !element.exists else { return }
        waitAndAssertTrue(element, timeout: .networkRequest, message)
    }

    private func hasText(_ element: XCUIElement) -> Bool {
        let value = element.getValue()
        return !value.isEmpty && value != element.placeholderValue
    }

    private func field(_ formField: FormField) -> XCUIElement {
        app.textFields[TangemPayAccessibilityIdentifiers.formField(formField.rawValue)].firstMatch
    }

    private func fieldError(_ formField: FormField) -> XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.formFieldError(formField.rawValue)].firstMatch
    }

    private func option(_ element: TangemPayBankTransferWizardScreenElement, label: String) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", element.accessibilityIdentifier, label))
            .firstMatch
    }
}

extension TangemPayBankTransferWizardScreen {
    enum TransferType {
        case ownAccount
        case thirdPartyAccount

        var title: String {
            switch self {
            case .ownAccount:
                Localization.tangempayWithdrawBankTransferTypeOwn
            case .thirdPartyAccount:
                Localization.tangempayWithdrawBankTransferTypeThirdParty
            }
        }
    }

    enum AccountType {
        case checking
        case saving

        var title: String {
            switch self {
            case .checking:
                Localization.tangempayWithdrawBankAccountTypeChecking
            case .saving:
                Localization.tangempayWithdrawBankAccountTypeSaving
            }
        }
    }

    enum FormField: String {
        case accountNumber
        case routingNumber
        case firstName
        case lastName
        case businessName
        case countryCode
        case region
        case city
        case line1
        case line2
        case postalCode
        case bankName
        case bankRegion
        case bankCity
        case bankLine1
        case bankPostalCode
    }

    enum RecipientName {
        case individual(firstName: String, lastName: String)
        case business(String)

        var fullName: String {
            switch self {
            case .individual(let firstName, let lastName):
                "\(firstName) \(lastName)"
            case .business(let businessName):
                businessName
            }
        }
    }

    struct RecipientDetails {
        let accountNumber: String
        let routingNumber: String
        let name: RecipientName
        let country: String
        let region: String
        let city: String
        let addressLine1: String
        let postalCode: String
    }

    struct BankDetails {
        let name: String
        let region: String
        let city: String
        let addressLine1: String
        let postalCode: String
    }
}

enum TangemPayBankTransferWizardScreenElement: String, UIElement {
    case transferTypeOption
    case transferTypeContinueButton
    case accountTypeOption
    case accountTypeContinueButton
    case formContinueButton
    case keyboardDismissButton

    var accessibilityIdentifier: String {
        switch self {
        case .transferTypeOption:
            TangemPayOfframpAccessibilityIdentifiers.transferTypeOption
        case .transferTypeContinueButton:
            TangemPayOfframpAccessibilityIdentifiers.transferTypeContinueButton
        case .accountTypeOption:
            TangemPayOfframpAccessibilityIdentifiers.accountTypeOption
        case .accountTypeContinueButton:
            TangemPayOfframpAccessibilityIdentifiers.accountTypeContinueButton
        case .formContinueButton:
            TangemPayOfframpAccessibilityIdentifiers.formContinueButton
        case .keyboardDismissButton:
            TangemPayOfframpAccessibilityIdentifiers.formKeyboardDismissButton
        }
    }
}

private extension TangemPayBankTransferWizardScreen {
    enum Constants {
        static let textEndOffset = CGVector(dx: 0.98, dy: 0.5)
        static let keyboardTopInset: CGFloat = 16
    }
}
