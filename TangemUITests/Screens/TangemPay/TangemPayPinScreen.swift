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
    private lazy var successTitle = staticText(.pinSuccessTitle)
    private lazy var doneButton = button(.pinDoneButton)

    @discardableResult
    func waitForPinEntryScreen() -> Self {
        XCTContext.runActivity(named: "Wait for PIN entry screen") { _ in
            waitAndAssertTrue(screenTitle, "PIN screen title should be displayed")
            waitAndAssertTrue(pinInputContainer, "PIN input container should be displayed")
            return self
        }
    }

    /// Redesigned flow auto-submits once a valid PIN of full length is entered.
    @discardableResult
    func enterPin(_ pin: String) -> Self {
        XCTContext.runActivity(named: "Enter 4-digit PIN") { _ in
            pinInputContainer.waitAndTap()
            app.typeText(pin)
            return self
        }
    }

    @discardableResult
    func waitForSuccessScreen() -> Self {
        XCTContext.runActivity(named: "Wait for PIN success screen") { _ in
            waitAndAssertTrue(successTitle, timeout: .networkRequest, "PIN success title should be displayed")
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
    case pinInputField
    case pinSuccessTitle
    case pinDoneButton

    var accessibilityIdentifier: String {
        switch self {
        case .pinScreenTitle:
            TangemPayAccessibilityIdentifiers.pinScreenTitle
        case .pinInputField:
            TangemPayAccessibilityIdentifiers.pinInputField
        case .pinSuccessTitle:
            TangemPayAccessibilityIdentifiers.pinSuccessTitle
        case .pinDoneButton:
            TangemPayAccessibilityIdentifiers.pinDoneButton
        }
    }
}
