//
//  TangemPayOrderCardDataScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayOrderCardDataScreen: ScreenBase<TangemPayOrderCardDataScreenElement> {
    private lazy var orderButton = button(.orderButton)
    private lazy var formScrollView = app.scrollViews
        .containing(NSPredicate(
            format: "elementType == %d AND label == %@",
            XCUIElement.ElementType.textField.rawValue,
            Field.nameOnCard.title
        ))
        .firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the delivery address screen") { _ in
            waitAndAssertTrue(orderButton, timeout: .networkRequest, "Order card button should be displayed on the delivery address screen")
            waitAndAssertTrue(app.staticTexts[Localization.tangempayOrderDataSubtitle].firstMatch, "'\(Localization.tangempayOrderDataSubtitle)' subtitle should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyPrefilledData(nameOnCard: String, country: String, email: String) -> Self {
        XCTContext.runActivity(named: "Verify the delivery address form is prefilled") { _ in
            verifyFieldValue(.nameOnCard, equals: nameOnCard)
            verifyFieldValue(.country, equals: country)
            verifyFieldValue(.email, equals: email)
            verifyPhoneMask()
            return self
        }
    }

    @discardableResult
    func verifyNameOnCard(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Verify Name on card is '\(expected)'") { _ in
            verifyFieldValue(.nameOnCard, equals: expected)
            return self
        }
    }

    @discardableResult
    func clearNameOnCard() -> Self {
        XCTContext.runActivity(named: "Clear Name on card") { _ in
            let nameField = field(.nameOnCard)
            waitAndAssertTrue(nameField, "Name on card field should be displayed")
            clearText(in: nameField)
            let isEmpty = XCTNSPredicateExpectation(
                predicate: NSPredicate { object, _ in (object as? XCUIElement)?.getValue().isEmpty == true },
                object: nameField
            )
            XCTAssertEqual(XCTWaiter().wait(for: [isEmpty], timeout: .conditional), .completed, "Name on card should be empty, got '\(nameField.getValue())'")
            return self
        }
    }

    @discardableResult
    func leaveEditableFieldsEmpty() -> Self {
        XCTContext.runActivity(named: "Move focus through every editable field and leave the form") { _ in
            focus(.nameOnCard)
            for _ in Constants.focusChainAfterName {
                app.typeText(Constants.nextFieldKey)
            }
            dismissKeyboard()
            return self
        }
    }

    @discardableResult
    func verifyRequiredErrors() -> Self {
        XCTContext.runActivity(named: "Verify every required field shows Required field") { _ in
            for field in Constants.requiredEditableFields {
                verifyError(on: field, equals: Localization.tangempayOrderDataFieldRequired)
            }
            XCTAssertFalse(errorLabel(.addressLine2).exists, "Address line 2 is optional and should not show an error")
            return self
        }
    }

    @discardableResult
    func enterText(_ text: String, into field: Field) -> Self {
        XCTContext.runActivity(named: "Enter '\(text)' into \(field.title)") { _ in
            focus(field)
            app.typeText(text)
            dismissKeyboard()
            return self
        }
    }

    @discardableResult
    func verifyLatinOnlyError(on field: Field) -> Self {
        XCTContext.runActivity(named: "Verify \(field.title) shows Use Latin characters only") { _ in
            verifyError(on: field, equals: Localization.tangempayOrderDataFieldLatinOnly)
            return self
        }
    }

    @discardableResult
    func verifyInvalidTextError(on field: Field) -> Self {
        XCTContext.runActivity(named: "Verify \(field.title) shows Invalid text") { _ in
            verifyError(on: field, equals: Localization.tangempayOrderDataFieldInvalid)
            return self
        }
    }

    @discardableResult
    func fillDeliveryAddress() -> Self {
        XCTContext.runActivity(named: "Fill in the delivery address") { _ in
            focus(.firstName)
            for value in Constants.Address.values {
                app.typeText(value + Constants.nextFieldKey)
            }
            app.typeText(Constants.Address.phoneDigits)
            dismissKeyboard()
            XCTAssertTrue(orderButton.waitForState(state: .enabled, for: .conditional), "Order card should be enabled once the address is complete")
            return self
        }
    }

    @discardableResult
    func tapOrderCard() -> TangemPayOrderCardSuccessScreen {
        XCTContext.runActivity(named: "Tap Order card") { _ in
            orderButton.waitAndTap()
            return TangemPayOrderCardSuccessScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func tapOrderCardExpectingError() -> TangemPayErrorRetrySheet {
        XCTContext.runActivity(named: "Tap Order card expecting an error") { _ in
            orderButton.waitAndTap()
            return TangemPayErrorRetrySheet(app).waitForSheet()
        }
    }

    private func field(_ field: Field) -> XCUIElement {
        app.textFields[field.title].firstMatch
    }

    private func errorLabel(_ field: Field) -> XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.orderCardDataFieldError(field.identifierSuffix)].firstMatch
    }

    private func focus(_ field: Field) {
        let element = self.field(field)
        waitAndAssertTrue(element, "\(field.title) field should be displayed")
        element.tap()
    }

    private func clearText(in element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: element.getValue().count + 1)
        app.typeText(deletes)
    }

    private func verifyPhoneMask() {
        let phoneField = field(.phone)
        waitAndAssertTrue(phoneField, "Phone field should be displayed")
        XCTAssertEqual(phoneField.placeholderValue, Constants.phoneMaskPlaceholder, "Phone should show the profile phone mask")
        XCTAssertTrue(phoneField.getValue().isEmpty, "Phone should not be prefilled with a number")
    }

    private func verifyFieldValue(_ field: Field, equals expected: String) {
        let element = self.field(field)
        waitAndAssertTrue(element, "\(field.title) field should be displayed")
        XCTAssertTrue(element.waitForValue(expected), "\(field.title) should be '\(expected)', got '\(element.getValue())'")
    }

    private func verifyError(on field: Field, equals expected: String) {
        let label = errorLabel(field)
        waitAndAssertTrue(label, timeout: .conditional, "\(field.title) should show an error")
        XCTAssertEqual(label.label, expected, "\(field.title) error should read '\(expected)'")
    }

    private func dismissKeyboard() {
        guard app.keyboards.firstMatch.exists else { return }
        let start = formScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98))
        start.press(forDuration: 0.1, thenDragTo: end)
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: .conditional), "Keyboard should be dismissed")
    }
}

extension TangemPayOrderCardDataScreen {
    enum Field {
        case nameOnCard
        case country
        case email
        case firstName
        case lastName
        case region
        case city
        case addressLine1
        case addressLine2
        case postalCode
        case phone

        var title: String {
            switch self {
            case .nameOnCard: Localization.tangempayOrderDataNameOnCard
            case .country: Localization.tangempayOrderDataCountry
            case .email: Localization.tangempayOrderDataEmail
            case .firstName: Localization.tangempayOrderDataFirstName
            case .lastName: Localization.tangempayOrderDataLastName
            case .region: Localization.tangempayOrderDataRegion
            case .city: Localization.tangempayOrderDataCity
            case .addressLine1: Localization.tangempayOrderDataAddressLine1
            case .addressLine2: Localization.tangempayOrderDataAddressLine2
            case .postalCode: Localization.tangempayOrderDataPostalCode
            case .phone: Localization.tangempayOrderDataPhone
            }
        }

        var identifierSuffix: String {
            "\(self)"
        }
    }
}

enum TangemPayOrderCardDataScreenElement: String, UIElement {
    case orderButton

    var accessibilityIdentifier: String {
        switch self {
        case .orderButton:
            TangemPayAccessibilityIdentifiers.orderCardDataOrderButton
        }
    }
}

private extension TangemPayOrderCardDataScreen {
    enum Constants {
        static let phoneMaskPlaceholder = "+1 ___-___-____"
        static let nextFieldKey = "\n"
        static let focusChainAfterName: [Field] = [.firstName, .lastName, .region, .city, .addressLine1, .addressLine2, .postalCode, .phone]
        static let requiredEditableFields: [Field] = [.nameOnCard, .firstName, .lastName, .region, .city, .addressLine1, .postalCode, .phone]

        enum Address {
            static let values = ["John", "Doe", "NY", "New York", "5th Avenue 1", "", "10001"]
            static let phoneDigits = "2025550123"
        }
    }
}
