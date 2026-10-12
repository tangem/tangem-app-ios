//
//  TangemPayMaximumCardsIssuedSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayMaximumCardsIssuedSheet: ScreenBase<TangemPayMaximumCardsIssuedSheetElement> {
    private lazy var gotItButton = button(.gotItButton)

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the maximum cards issued sheet") { _ in
            waitAndAssertTrue(gotItButton, timeout: .networkRequest, "Got it button should be displayed on the maximum cards sheet")
            return self
        }
    }

    @discardableResult
    func verifyContent(title: String, description: String) -> Self {
        XCTContext.runActivity(named: "Verify the maximum cards issued sheet content") { _ in
            waitAndAssertTrue(app.staticTexts[title].firstMatch, "'\(title)' should be displayed on the maximum cards sheet")
            waitAndAssertTrue(app.staticTexts[description].firstMatch, "'\(description)' should be displayed on the maximum cards sheet")
            return self
        }
    }
}

enum TangemPayMaximumCardsIssuedSheetElement: String, UIElement {
    case gotItButton

    var accessibilityIdentifier: String {
        switch self {
        case .gotItButton:
            TangemPayAccessibilityIdentifiers.maximumCardsIssuedConfirmButton
        }
    }
}
