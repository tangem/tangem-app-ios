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
        XCTContext.runActivity(named: "Fill in the recipient details of \(details.firstName) \(details.lastName)") { _ in
            waitAndAssertTrue(field(.accountNumber), timeout: .networkRequest, "Recipient details form should be displayed")
            enter(details.accountNumber, into: .accountNumber)
            enter(details.routingNumber, into: .routingNumber)
            enter(details.firstName, into: .firstName)
            enter(details.lastName, into: .lastName)
            selectCountry(details.country, region: details.region)
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
            waitAndAssertTrue(field(.bankName), timeout: .networkRequest, "Bank details form should be displayed")
            enter(details.name, into: .bankName)
            selectOption(details.region, from: .bankRegion)
            enter(details.city, into: .bankCity)
            enter(details.addressLine1, into: .bankLine1)
            enter(details.postalCode, into: .bankPostalCode)
            tapFormContinue()
            return TangemPayBankTransferConfirmScreen(app).waitForScreen()
        }
    }

    private func selectCountry(_ country: String, region: String) {
        XCTContext.runActivity(named: "Select \(country), \(region)") { _ in
            selectOption(country, from: .countryCode)
            geoRow(region).waitAndTap(timeout: .networkRequest)
            XCTAssertTrue(
                field(.countryCode).waitForValue(where: { $0.contains(country) }),
                "Country should read '\(country)'. Actual: '\(field(.countryCode).getValue())'"
            )
        }
    }

    private func selectOption(_ option: String, from formField: FormField) {
        dismissKeyboard()
        let element = field(formField)
        waitAndAssertTrue(element, "\(formField.rawValue) field should be displayed")
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        geoRow(option).waitAndTap(timeout: .networkRequest)
    }

    private func enter(_ text: String, into formField: FormField) {
        dismissKeyboard()
        let element = field(formField)
        waitAndAssertTrue(element, "\(formField.rawValue) field should be displayed")
        element.tap()
        element.typeText(text)
        XCTAssertTrue(
            element.waitForValue(where: { $0 == text }),
            "\(formField.rawValue) should read '\(text)'. Actual: '\(element.getValue())'"
        )
    }

    private func tapFormContinue() {
        dismissKeyboard()
        XCTAssertTrue(formContinueButton.waitForState(state: .enabled, for: .conditional), "Continue should be enabled once the form is filled")
        formContinueButton.waitAndTap()
    }

    private func dismissKeyboard() {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return }
        keyboardDismissButton.waitAndTap()
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: .conditional), "Keyboard should be dismissed")
    }

    private func field(_ formField: FormField) -> XCUIElement {
        app.textFields[TangemPayAccessibilityIdentifiers.formField(formField.rawValue)].firstMatch
    }

    private func option(_ element: TangemPayBankTransferWizardScreenElement, label: String) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", element.accessibilityIdentifier, label))
            .firstMatch
    }

    private func geoRow(_ title: String) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", TangemPayAccessibilityIdentifiers.geoSelectionRow, title))
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

    struct RecipientDetails {
        let accountNumber: String
        let routingNumber: String
        let firstName: String
        let lastName: String
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
    enum FormField: String {
        case accountNumber
        case routingNumber
        case firstName
        case lastName
        case countryCode
        case city
        case line1
        case postalCode
        case bankName
        case bankRegion
        case bankCity
        case bankLine1
        case bankPostalCode
    }
}
