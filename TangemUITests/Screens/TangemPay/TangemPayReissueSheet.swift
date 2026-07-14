//
//  TangemPayReissueSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayReissueSheet: Screen {
    private static let title = "Replace your card?"
    private static let description = "This generates a new set of card details. Your old details will stop working. You can't undo this."
    private static let feeLabel = "Replacement fee"
    private static let unableToCoverFeeTitle = "Unable to cover fee"

    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    private var confirmButton: XCUIElement {
        app.buttons[TangemPayAccessibilityIdentifiers.reissueSheetConfirmButton].firstMatch
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for card reissue bottom sheet") { _ in
            waitAndAssertTrue(confirmButton, "Replace card confirm button should be displayed on reissue sheet")
            return self
        }
    }

    @discardableResult
    func verifyReplaceCardContent(feeValue: String) -> Self {
        XCTContext.runActivity(named: "Verify reissue sheet content with fee '\(feeValue)'") { _ in
            waitAndAssertTrue(app.staticTexts[Self.title].firstMatch, "Reissue sheet title should be displayed")
            waitAndAssertTrue(app.staticTexts[Self.description].firstMatch, "Reissue sheet description should be displayed")
            waitAndAssertTrue(app.staticTexts[Self.feeLabel].firstMatch, "Replacement fee label should be displayed")
            waitAndAssertTrue(app.staticTexts[feeValue].firstMatch, "Replacement fee value '\(feeValue)' should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyUnableToCoverFee() -> Self {
        XCTContext.runActivity(named: "Verify reissue sheet shows 'Unable to cover fee' state") { _ in
            waitAndAssertTrue(app.staticTexts[Self.unableToCoverFeeTitle].firstMatch, "'Unable to cover fee' title should be displayed")
            return self
        }
    }

    @discardableResult
    func tapConfirm() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Replace card confirm on reissue sheet") { _ in
            confirmButton.waitAndTap()
            XCTAssertTrue(
                confirmButton.waitForNonExistence(timeout: .robustUIUpdate),
                "Reissue sheet should be dismissed after confirming"
            )
            return TangemPayCardDetailsScreen(app)
        }
    }

    @discardableResult
    func tapAddFunds() -> TangemPayAddFundsSheet {
        XCTContext.runActivity(named: "Tap Add funds on 'Unable to cover fee' reissue sheet") { _ in
            confirmButton.waitAndTap()
            return TangemPayAddFundsSheet(app)
        }
    }
}
