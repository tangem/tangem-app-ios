//
//  TangemPayActivateCardScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayActivateCardScreen: ScreenBase<TangemPayActivateCardScreenElement> {
    private lazy var hint = staticText(.hint)
    private lazy var continueButton = button(.continueButton)
    private lazy var title = app.staticTexts[Localization.tangempayCardDetailsActivate].firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the Activate card screen") { _ in
            waitAndAssertTrue(continueButton, timeout: .networkRequest, "Continue button should be displayed on the Activate card screen")
            return self
        }
    }

    @discardableResult
    func verifyInitialState() -> Self {
        XCTContext.runActivity(named: "Verify the Activate card screen initial state") { _ in
            waitAndAssertTrue(title, "'\(Localization.tangempayCardDetailsActivate)' header should be displayed")
            verifyHint(Localization.tangempayCardActivationDescription)
            waitAndAssertTrue(app.keyboards.firstMatch, timeout: .conditional, "The last-four-digits entry should be focused")
            XCTAssertTrue(continueButton.waitForState(state: .disabled, for: .conditional), "Continue should be disabled before four digits are entered")
            return self
        }
    }

    @discardableResult
    func enterLastFourDigits(_ digits: String) -> Self {
        XCTContext.runActivity(named: "Enter the last four digits '\(digits)'") { _ in
            waitAndAssertTrue(app.keyboards.firstMatch, timeout: .conditional, "Keyboard should be shown for the digits entry")
            app.typeText(digits)
            XCTAssertTrue(continueButton.waitForState(state: .enabled, for: .conditional), "Continue should be enabled after four digits")
            return self
        }
    }

    @discardableResult
    func tapContinue() -> Self {
        XCTContext.runActivity(named: "Tap Continue") { _ in
            continueButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyActivatingHint() -> Self {
        XCTContext.runActivity(named: "Verify the activation is in progress") { _ in
            verifyHint(Localization.tangempayCardActivationInProgress)
            return self
        }
    }

    @discardableResult
    func verifyInvalidDigitsHint() -> Self {
        XCTContext.runActivity(named: "Verify the invalid digits error") { _ in
            verifyHint(Localization.tangempayCardActivationError, timeout: .networkRequest)
            return self
        }
    }

    @discardableResult
    func waitForScreenClosed() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Wait for the Activate card screen to close") { _ in
            XCTAssertTrue(continueButton.waitForNonExistence(timeout: .networkRequest), "Activate card screen should close after the activation order is placed")
            return TangemPayCardDetailsScreen(app)
        }
    }

    @discardableResult
    func close<Destination: Screen>(to destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Close the Activate card screen") { _ in
            guard let closeButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonClose)).firstHittableElement() else {
                XCTFail("Close button should become hittable")
                return Destination(app)
            }
            closeButton.tap()
            XCTAssertTrue(continueButton.waitForNonExistence(timeout: .conditional), "Activate card screen should be closed")
            return Destination(app)
        }
    }

    private func verifyHint(_ expected: String, timeout: TimeInterval = .conditional) {
        waitAndAssertTrue(hint, "Activation hint should be displayed")
        let matches = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: hint)
        XCTAssertEqual(XCTWaiter().wait(for: [matches], timeout: timeout), .completed, "Hint should read '\(expected)', got '\(hint.label)'")
    }
}

enum TangemPayActivateCardScreenElement: String, UIElement {
    case hint
    case continueButton

    var accessibilityIdentifier: String {
        switch self {
        case .hint:
            TangemPayAccessibilityIdentifiers.activateCardHint
        case .continueButton:
            TangemPayAccessibilityIdentifiers.activateCardContinueButton
        }
    }
}
