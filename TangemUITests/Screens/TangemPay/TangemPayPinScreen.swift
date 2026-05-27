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
    private lazy var screenDescription = staticText(.pinScreenDescription)
    private lazy var pinInputContainer = otherElement(.pinInputField)
    private lazy var submitButton = button(.pinSubmitButton)
    private lazy var successTitle = staticText(.pinSuccessTitle)
    private lazy var successDescription = staticText(.pinSuccessDescription)
    private lazy var doneButton = button(.pinDoneButton)

    @discardableResult
    func waitForPinEntryScreen() -> Self {
        XCTContext.runActivity(named: "Wait for PIN entry screen") { _ in
            waitAndAssertTrue(screenTitle, "PIN screen title should be displayed")
            waitAndAssertTrue(screenDescription, "PIN screen description should be displayed")
            return self
        }
    }

    @discardableResult
    func verifySubmitDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Submit button is disabled") { _ in
            waitAndAssertTrue(submitButton, "Submit button should exist")
            XCTAssertFalse(submitButton.isEnabled, "Submit button should be disabled before PIN is entered")
            return self
        }
    }

    @discardableResult
    func enterPin(_ pin: String) -> Self {
        XCTContext.runActivity(named: "Enter 4-digit PIN") { _ in
            waitAndAssertTrue(pinInputContainer, "PIN input container should exist")
            app.typeText(pin)
            return self
        }
    }

    @discardableResult
    func verifySubmitEnabled() -> Self {
        XCTContext.runActivity(named: "Verify Submit button is enabled") { _ in
            XCTAssertTrue(
                submitButton.waitForState(state: .enabled, for: .conditional),
                "Submit button should become enabled after valid PIN is entered"
            )
            return self
        }
    }

    @discardableResult
    func tapSubmit() -> Self {
        XCTContext.runActivity(named: "Tap Submit button") { _ in
            submitButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func waitForSuccessScreen() -> Self {
        XCTContext.runActivity(named: "Wait for PIN success screen") { _ in
            waitAndAssertTrue(successTitle, timeout: .networkRequest, "PIN success title should be displayed")
            waitAndAssertTrue(successDescription, "PIN success description should be displayed")
            waitAndAssertTrue(doneButton, "Done button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapDone() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Done button") { _ in
            doneButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }
}

enum TangemPayPinScreenElement: String, UIElement {
    case pinScreenTitle
    case pinScreenDescription
    case pinInputField
    case pinSubmitButton
    case pinSuccessTitle
    case pinSuccessDescription
    case pinDoneButton

    var accessibilityIdentifier: String {
        switch self {
        case .pinScreenTitle:
            TangemPayAccessibilityIdentifiers.pinScreenTitle
        case .pinScreenDescription:
            TangemPayAccessibilityIdentifiers.pinScreenDescription
        case .pinInputField:
            TangemPayAccessibilityIdentifiers.pinInputField
        case .pinSubmitButton:
            TangemPayAccessibilityIdentifiers.pinSubmitButton
        case .pinSuccessTitle:
            TangemPayAccessibilityIdentifiers.pinSuccessTitle
        case .pinSuccessDescription:
            TangemPayAccessibilityIdentifiers.pinSuccessDescription
        case .pinDoneButton:
            TangemPayAccessibilityIdentifiers.pinDoneButton
        }
    }
}
