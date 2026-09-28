//
//  TangemPayCardsLimitReachedSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayCardsLimitReachedSheet: ScreenBase<TangemPayCardsLimitReachedSheetElement> {
    private lazy var upgradePlanButton = button(.upgradePlanButton)
    private lazy var cancelButton = button(.cancelButton)

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the cards limit reached sheet") { _ in
            waitAndAssertTrue(upgradePlanButton, timeout: .networkRequest, "Upgrade plan button should be displayed on the cards limit sheet")
            return self
        }
    }

    @discardableResult
    func verifyContent(title: String, description: String) -> Self {
        XCTContext.runActivity(named: "Verify the cards limit sheet content") { _ in
            waitAndAssertTrue(app.staticTexts[title].firstMatch, "'\(title)' should be displayed on the cards limit sheet")
            waitAndAssertTrue(app.staticTexts[description].firstMatch, "'\(description)' should be displayed on the cards limit sheet")
            return self
        }
    }

    @discardableResult
    func verifyCancelButton() -> Self {
        XCTContext.runActivity(named: "Verify the cards limit sheet offers Cancel") { _ in
            waitAndAssertTrue(cancelButton, "Cancel button should be displayed on the cards limit sheet")
            XCTAssertEqual(cancelButton.label, Constants.cancelTitle, "Secondary button on the cards limit sheet should read '\(Constants.cancelTitle)'")
            return self
        }
    }

    @discardableResult
    func tapUpgradePlan() -> TangemPaySelectPlanScreen {
        XCTContext.runActivity(named: "Tap Upgrade plan") { _ in
            upgradePlanButton.waitAndTap()
            return TangemPaySelectPlanScreen(app)
        }
    }
}

enum TangemPayCardsLimitReachedSheetElement: String, UIElement {
    case upgradePlanButton
    case cancelButton

    var accessibilityIdentifier: String {
        switch self {
        case .upgradePlanButton:
            TangemPayAccessibilityIdentifiers.cardsLimitReachedConfirmButton
        case .cancelButton:
            TangemPayAccessibilityIdentifiers.popupSecondaryButton
        }
    }
}

private extension TangemPayCardsLimitReachedSheet {
    enum Constants {
        static let cancelTitle = "Cancel"
    }
}
