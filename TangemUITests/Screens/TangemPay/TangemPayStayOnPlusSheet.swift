//
//  TangemPayStayOnPlusSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayStayOnPlusSheet: ScreenBase<TangemPayStayOnPlusSheetElement> {
    private lazy var stayButton = button(.stayButton)

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the stay on plan sheet") { _ in
            waitAndAssertTrue(stayButton, timeout: .networkRequest, "Stay button should be displayed on the stay on plan sheet")
            return self
        }
    }

    @discardableResult
    func verifyContent(title: String, description: String) -> Self {
        XCTContext.runActivity(named: "Verify the stay on plan sheet content") { _ in
            waitAndAssertTrue(app.staticTexts[title].firstMatch, "'\(title)' should be displayed on the stay on plan sheet")
            waitAndAssertTrue(app.staticTexts[description].firstMatch, "'\(description)' should be displayed on the stay on plan sheet")
            return self
        }
    }

    @discardableResult
    func tapStay() -> TangemPayCurrentPlanScreen {
        XCTContext.runActivity(named: "Confirm staying on the current plan") { _ in
            stayButton.waitAndTap()
            return TangemPayCurrentPlanScreen(app)
        }
    }
}

enum TangemPayStayOnPlusSheetElement: String, UIElement {
    case stayButton

    var accessibilityIdentifier: String {
        switch self {
        case .stayButton:
            TangemPayAccessibilityIdentifiers.stayOnPlusConfirmButton
        }
    }
}
