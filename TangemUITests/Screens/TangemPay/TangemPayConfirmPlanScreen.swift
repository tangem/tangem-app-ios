//
//  TangemPayConfirmPlanScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayConfirmPlanScreen: ScreenBase<TangemPayConfirmPlanScreenElement> {
    private lazy var confirmButton = button(.confirmButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Confirm plan screen") { _ in
            waitAndAssertTrue(confirmButton, timeout: .networkRequest, "Confirm button should be displayed on Confirm plan screen")
            return self
        }
    }

    @discardableResult
    func verifyTitle(contains text: String) -> Self {
        XCTContext.runActivity(named: "Verify the confirmation title contains '\(text)'") { _ in
            let matching = app.staticTexts
                .matching(NSPredicate(format: "identifier == %@ AND label CONTAINS[c] %@", TangemPayAccessibilityIdentifiers.confirmPlanTitle, text))
                .firstMatch
            waitAndAssertTrue(matching, timeout: .networkRequest, "Confirmation title should contain '\(text)'")
            return self
        }
    }

    @discardableResult
    func verifyPoint(contains text: String) -> Self {
        XCTContext.runActivity(named: "Verify a confirmation point contains '\(text)'") { _ in
            let point = app.staticTexts.matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, text)).firstMatch
            waitAndAssertTrue(point, "A confirmation point containing '\(text)' should be displayed")
            return self
        }
    }

    @discardableResult
    func tapConfirm() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Confirm the plan selection") { _ in
            confirmButton.waitAndTap()
            return TangemPayMainScreen(app)
        }
    }

    @discardableResult
    func tapConfirmExpectingCurrentPlan() -> TangemPayCurrentPlanScreen {
        XCTContext.runActivity(named: "Confirm the plan selection and stay on Current plan") { _ in
            confirmButton.waitAndTap()
            return TangemPayCurrentPlanScreen(app)
        }
    }
}

enum TangemPayConfirmPlanScreenElement: String, UIElement {
    case confirmButton

    var accessibilityIdentifier: String {
        switch self {
        case .confirmButton:
            TangemPayAccessibilityIdentifiers.confirmPlanPrimaryButton
        }
    }
}
