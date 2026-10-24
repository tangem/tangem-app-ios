//
//  ApplePaySheetScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class ApplePaySheetScreen: Screen {
    let app: XCUIApplication

    private let sheet = XCUIApplication(bundleIdentifier: Constants.sheetBundleId)

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheetDisplayed(cryptoAmount: String) -> Self {
        XCTContext.runActivity(named: "Validate Apple Pay sheet is displayed for \(cryptoAmount)") { _ in
            waitAndAssertTrue(payButton, "Apple Pay sheet Pay button should exist")
            XCTAssertTrue(
                payButton.label.filter(\.isNumber).contains(cryptoAmount.filter(\.isNumber)),
                "Apple Pay sheet total '\(payButton.label)' should contain '\(cryptoAmount)'"
            )
        }
        return self
    }

    func close() -> OnrampScreen {
        XCTContext.runActivity(named: "Close Apple Pay sheet") { _ in
            sheet.buttons.matching(NSPredicate(format: "identifier == %@ OR label == %@", Constants.Identifier.dismiss, Constants.close)).firstMatch.waitAndTap()
            XCTAssertTrue(payButton.waitForState(state: .doesntExist), "Apple Pay sheet should be dismissed")
            return OnrampScreen(app)
        }
    }

    func confirmPayment(email: String, billing: ApplePayBillingAddress) -> OnrampKYCVerificationSheetScreen {
        XCTContext.runActivity(named: "Confirm Apple Pay payment with passcode") { _ in
            waitAndAssertTrue(payButton, "Apple Pay sheet Pay button should exist")
            fillEmailIfNeeded(email)
            fillBillingAddressIfNeeded(billing)
            payButton.waitAndTap()
            guard let passcodeButton = sheet.buttons.matching(identifier: Constants.passcodeButton).firstHittableElement() else {
                XCTFail("Pay with Passcode button should become hittable")
                return OnrampKYCVerificationSheetScreen(app)
            }
            passcodeButton.tap()
            return OnrampKYCVerificationSheetScreen(app)
        }
    }

    private func fillEmailIfNeeded(_ email: String) {
        let addEmailRow = sheet.buttons[Constants.addEmail].firstMatch
        let savedContactRow = sheet.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@ OR (identifier == %@ AND label CONTAINS %@)",
            Constants.contactPrefix, Constants.Identifier.contact, "@"
        )).firstMatch
        waitForAny(addEmailRow, savedContactRow, "Apple Pay contact row should be displayed")
        guard addEmailRow.exists else { return }

        addEmailRow.tap()
        let addEmailOptions = sheet.buttons.matching(identifier: Constants.addEmail)
        waitForButtonCount(addEmailOptions, atLeast: 2)
        addEmailOptions.allElementsBoundByIndex.last?.tap()

        let emailField = sheet.textFields[Constants.Field.email]
        emailField.waitAndTap()
        emailField.typeText(email)
        sheet.buttons[Constants.Identifier.done].firstMatch.waitAndTap()
        waitAndAssertTrue(payButton, "Apple Pay sheet should return to the payment summary after adding email")
    }

    private func fillBillingAddressIfNeeded(_ billing: ApplePayBillingAddress) {
        let billingRow = sheet.buttons[Constants.Identifier.billing].firstMatch
        let cardRow = billingRow.exists ? billingRow : sheet.buttons[Constants.Identifier.card].firstMatch
        waitAndAssertTrue(cardRow, "Apple Pay card row should exist")
        guard cardRow.label.contains(Constants.addBilling) else { return }

        cardRow.tap()
        let firstField = sheet.textFields[billing.fields[0].name]
        let billingOptions = sheet.buttons.matching(NSPredicate(format: "label CONTAINS %@", Constants.addBilling))
        waitForAny(firstField, billingOptions.element(boundBy: 1), "Apple Pay billing form or its options should be displayed")
        if !firstField.exists {
            billingOptions.allElementsBoundByIndex.last?.tap()
        }

        for (field, value) in billing.fields {
            let textField = sheet.textFields[field]
            scrollUntilHittable(textField)
            textField.waitAndTap()
            textField.typeText(value)
        }

        let doneButtons = sheet.buttons.matching(NSPredicate(format: "identifier == %@ OR label == %@", Constants.Identifier.done, Constants.Identifier.done))
        waitAndAssertTrue(doneButtons.firstMatch, "Apple Pay Done button should exist")
        if doneButtons.count >= 2 {
            doneButtons.allElementsBoundByIndex.last?.tap()
        }
        doneButtons.firstMatch.waitAndTap()
        if doneButtons.firstMatch.waitForExistence(timeout: .conditional) {
            doneButtons.firstMatch.tap()
        }
        waitAndAssertTrue(payButton, "Apple Pay sheet should return to the payment summary after adding billing address")
    }

    private func waitForAny(_ first: XCUIElement, _ second: XCUIElement, _ message: String) {
        let predicate = NSPredicate { _, _ in first.exists || second.exists }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate), .completed, message)
    }

    private func waitForButtonCount(_ query: XCUIElementQuery, atLeast count: Int) {
        let countPredicate = NSPredicate { _, _ in query.count >= count }
        let expectation = XCTNSPredicateExpectation(predicate: countPredicate, object: nil)
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
            .completed,
            "Apple Pay sheet should show at least \(count) matching buttons"
        )
    }

    private func scrollUntilHittable(_ element: XCUIElement) {
        waitAndAssertTrue(element, "Apple Pay sheet field should exist")
        let start = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        let end = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        for _ in 0 ..< Constants.scrollAttempts where !element.isHittable {
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        XCTAssertTrue(element.isHittable, "Apple Pay sheet field '\(element.identifier)' should become hittable after scrolling")
    }

    private var payButton: XCUIElement {
        sheet.descendants(matching: .any).matching(identifier: Constants.Identifier.total).firstMatch
    }
}

struct ApplePayBillingAddress {
    let firstName: String
    let lastName: String
    let street: String
    let city: String
    let state: String
    let zip: String

    var fields: [(name: String, value: String)] {
        [
            ("First Name", firstName),
            ("Last Name", lastName),
            ("Street", street),
            ("City", city),
            ("State", state),
            ("ZIP", zip),
        ]
    }
}

private extension ApplePaySheetScreen {
    enum Constants {
        static let sheetBundleId = "com.apple.PassbookUIService"
        static let addEmail = "Add Email Address"
        static let addBilling = "Add Billing Address"
        static let contactPrefix = "Contact"
        static let close = "Close"
        static let passcodeButton = "Pay with Passcode"
        static let scrollAttempts = 3

        enum Identifier {
            static let total = "total"
            static let dismiss = "dismiss"
            static let card = "pass"
            static let billing = "billing-address"
            static let contact = "shipping-email"
            static let done = "Done"
        }

        enum Field {
            static let email = "Email"
        }
    }
}
