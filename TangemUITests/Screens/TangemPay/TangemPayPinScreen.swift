//
//  TangemPayPinScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayPinScreen: ScreenBase<TangemPayPinScreenElement> {
    private lazy var screenTitle = staticText(.pinScreenTitle)
    private lazy var pinInputContainer = otherElement(.pinInputField)
    private lazy var keyboard = app.keyboards.firstMatch
    /// The container identifier on the PIN stack overwrites identifiers of its children, so the error is matched by label.
    private lazy var validationError = app.staticTexts
        .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, Localization.visaOnboardingPinValidationErrorMessage))
        .firstMatch
    private lazy var successTitle = app.staticTexts
        .matching(NSPredicate(format: "label == %@", Localization.tangempayCardDetailsChangePinSuccessTitle))
        .firstMatch
    private lazy var successDescription = app.staticTexts
        .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, Localization.tangempayCardDetailsChangePinSuccessDescription))
        .firstMatch
    private lazy var successCloseButton = app.buttons
        .matching(NSPredicate(format: "label == %@", Localization.commonClose))
        .firstMatch
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForPinEntryScreen() -> Self {
        XCTContext.runActivity(named: "Wait for PIN entry screen") { _ in
            waitAndAssertTrue(screenTitle, "PIN screen title should be displayed")
            waitAndAssertTrue(pinInputContainer, "PIN input container should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyNumericKeyboardDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify numeric keyboard is displayed") { _ in
            waitAndAssertTrue(keyboard, "Numeric keyboard should be displayed")
            return self
        }
    }

    /// Redesigned flow auto-submits once a valid PIN of full length is entered.
    @discardableResult
    func enterPin(_ pin: String) -> Self {
        enterDigits(pin)
    }

    @discardableResult
    func enterDigits(_ digits: String) -> Self {
        XCTContext.runActivity(named: "Enter digits '\(digits)'") { _ in
            focusPinInput()
            typePerCharacter(digits)
            return self
        }
    }

    /// A failed validation keeps the entered digits, and the input ignores anything above its length.
    @discardableResult
    func deleteDigits(_ count: Int) -> Self {
        XCTContext.runActivity(named: "Delete \(count) entered digit(s)") { _ in
            focusPinInput()
            typePerCharacter(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count))
            return self
        }
    }

    @discardableResult
    func waitForValidationError() -> Self {
        XCTContext.runActivity(named: "Wait for PIN validation error") { _ in
            waitAndAssertTrue(
                validationError,
                timeout: .conditional,
                "PIN validation error about sequences and repeats should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyValidationErrorHidden() -> Self {
        XCTContext.runActivity(named: "Verify PIN validation error is hidden") { _ in
            XCTAssertTrue(
                validationError.waitForNonExistence(timeout: .conditional),
                "PIN validation error should be hidden once the entered PIN changes"
            )
            return self
        }
    }

    @discardableResult
    func waitForSuccessScreen() -> Self {
        XCTContext.runActivity(named: "Wait for PIN success screen") { _ in
            waitAndAssertTrue(successTitle, timeout: .networkRequest, "PIN success title should be displayed")
            waitAndAssertTrue(successCloseButton, "Close button should be displayed on the PIN success screen")
            return self
        }
    }

    @discardableResult
    func verifySuccessContent() -> Self {
        XCTContext.runActivity(named: "Verify PIN success screen content") { _ in
            waitForSuccessScreen()
            XCTAssertEqual(successTitle.label, Localization.tangempayCardDetailsChangePinSuccessTitle, "PIN success title should confirm the created PIN")
            waitAndAssertTrue(successDescription, "PIN success description should be displayed")
            return self
        }
    }

    @discardableResult
    func tapSuccessClose() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Close on the PIN success screen") { _ in
            successCloseButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }

    @discardableResult
    func close() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Close PIN entry screen") { _ in
            closeButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }

    /// Tapping the input again while the keyboard is already up re-triggers the responder binding and drops keystrokes.
    private func focusPinInput() {
        guard !keyboard.exists else { return }

        pinInputContainer.waitAndTap()
        waitAndAssertTrue(keyboard, "Numeric keyboard should be displayed after tapping the PIN input")
    }

    /// Per character, so the input length clamp settles between keystrokes.
    private func typePerCharacter(_ text: String) {
        for character in text {
            app.typeText(String(character))
        }
    }
}

enum TangemPayPinScreenElement: String, UIElement {
    case pinScreenTitle
    case pinInputField
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .pinScreenTitle:
            TangemPayAccessibilityIdentifiers.pinScreenTitle
        case .pinInputField:
            TangemPayAccessibilityIdentifiers.pinInputField
        case .closeButton:
            CommonUIAccessibilityIdentifiers.closeButton
        }
    }
}
