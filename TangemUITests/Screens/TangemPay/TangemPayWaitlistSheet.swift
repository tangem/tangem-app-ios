//
//  TangemPayWaitlistSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayWaitlistSheet: ScreenBase<TangemPayWaitlistSheetElement> {
    private lazy var emailField = textField(.emailField)
    private lazy var emailError = staticText(.emailError)
    private lazy var marketingConsentCheckbox = button(.marketingConsentCheckbox)
    private lazy var title = app.staticTexts[Localization.tangempayWaitlistTitle.trimmingCharacters(in: .whitespacesAndNewlines)].firstMatch
    private lazy var saveButton = app.buttons[Localization.commonSave].firstMatch
    private lazy var privacyPolicyLink = app.links[Localization.commonPrivacyPolicy].firstMatch

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for Join the waitlist sheet") { _ in
            waitAndAssertTrue(emailField, timeout: .conditional, "Waitlist email field should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyEmailFieldFocused() -> Self {
        XCTContext.runActivity(named: "Verify the email field is focused") { _ in
            let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: emailField)
            XCTAssertEqual(XCTWaiter().wait(for: [focused], timeout: .conditional), .completed, "Email field should get keyboard focus")
            waitAndAssertTrue(app.keyboards.firstMatch, timeout: .conditional, "Keyboard should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyContent() -> Self {
        XCTContext.runActivity(named: "Verify Join the waitlist sheet content") { _ in
            waitAndAssertTrue(title, "Waitlist title should be displayed")
            waitAndAssertTrue(app.staticTexts[Localization.tangempayWaitlistDescription].firstMatch, "Waitlist description should be displayed")
            XCTAssertEqual(emailField.placeholderValue, Localization.tangempayWaitlistEmailPlaceholder, "Email placeholder should match")
            waitAndAssertTrue(marketingConsentCheckbox, "Marketing consent checkbox should be displayed")
            let consentText = app.staticTexts
                .matching(NSPredicate(format: "label == %@", Localization.tangempayWaitlistMarketingConsent(Localization.commonPrivacyPolicy)))
                .firstMatch
            waitAndAssertTrue(consentText, "Marketing consent text should be displayed")
            waitAndAssertTrue(privacyPolicyLink, "Privacy Policy link should be displayed")
            waitAndAssertTrue(saveButton, "Save button should be displayed")
            return self
        }
    }

    @discardableResult
    func enterEmail(_ email: String) -> Self {
        XCTContext.runActivity(named: "Enter email '\(email)'") { _ in
            replaceValueTypingFromEnd(in: emailField, with: email)
            return self
        }
    }

    @discardableResult
    func tapMarketingConsent() -> Self {
        XCTContext.runActivity(named: "Tap the marketing consent checkbox") { _ in
            marketingConsentCheckbox.waitAndTap()
            let checked = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isSelected == true"), object: marketingConsentCheckbox)
            XCTAssertEqual(XCTWaiter().wait(for: [checked], timeout: .conditional), .completed, "Marketing consent should be checked")
            return self
        }
    }

    @discardableResult
    func tapSave() -> Self {
        XCTContext.runActivity(named: "Tap Save") { _ in
            saveButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyEmailFormatError() -> Self {
        XCTContext.runActivity(named: "Verify the incorrect email format error") { _ in
            waitAndAssertTrue(emailError, timeout: .conditional, "Email format error should be displayed")
            XCTAssertEqual(emailError.label, Localization.commonErrorEmailIncorrectFormat, "Email format error text should match")
            return self
        }
    }

    @discardableResult
    func saveExpectingJoined() -> DetailsScreen {
        XCTContext.runActivity(named: "Tap Save and expect the waitlist to be joined") { _ in
            saveButton.waitAndTap()
            let toast = app.staticTexts[CommonUIAccessibilityIdentifiers.successToast].firstMatch
            waitAndAssertTrue(toast, timeout: .networkRequest, "Joined waitlist toast should be displayed")
            XCTAssertEqual(toast.label, Localization.tangempayWaitlistJoinedMessage, "Toast should confirm joining the waitlist")
            XCTAssertTrue(emailField.waitForNonExistence(timeout: .robustUIUpdate), "Waitlist sheet should be closed")
            return DetailsScreen(app)
        }
    }
}

enum TangemPayWaitlistSheetElement: UIElement {
    case emailField
    case emailError
    case marketingConsentCheckbox

    var accessibilityIdentifier: String {
        switch self {
        case .emailField:
            TangemPayAccessibilityIdentifiers.formField(Constants.emailFieldId)
        case .emailError:
            TangemPayAccessibilityIdentifiers.formFieldError(Constants.emailFieldId)
        case .marketingConsentCheckbox:
            TangemPayAccessibilityIdentifiers.waitlistMarketingConsentCheckbox
        }
    }
}

private extension TangemPayWaitlistSheetElement {
    enum Constants {
        static let emailFieldId = "email"
    }
}
