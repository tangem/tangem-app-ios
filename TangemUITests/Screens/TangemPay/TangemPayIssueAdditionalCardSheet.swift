//
//  TangemPayIssueAdditionalCardSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayIssueAdditionalCardSheet: Screen {
    private static let title = "Issue an additional card?"
    private static let description = "It generates a new set of card details"
    private static let feeLabel = "Issue fee"
    private static let unableToCoverFeeTitle = "Unable to cover fee"
    private static let unableToCoverFeeMessage = "Deposit USDC to payment account to cover the issuing fee"

    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    private var issueCardButton: XCUIElement {
        app.buttons[TangemPayAccessibilityIdentifiers.issueAdditionalCardSheetConfirmButton].firstMatch
    }

    /// The Add funds button of the shared Tangem Pay fee popup, reused by both the reissue and the issue flows.
    private var addFundsButton: XCUIElement {
        app.buttons[TangemPayAccessibilityIdentifiers.reissueSheetAddFundsButton].firstMatch
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for issue additional card bottom sheet") { _ in
            waitAndAssertTrue(issueCardButton, "Issue card button should be displayed on issue additional card sheet")
            return self
        }
    }

    @discardableResult
    func verifyContent(feeValue: String) -> Self {
        XCTContext.runActivity(named: "Verify issue additional card sheet content with fee '\(feeValue)'") { _ in
            waitAndAssertTrue(app.staticTexts[Self.title].firstMatch, "Issue additional card sheet title should be displayed")
            waitAndAssertTrue(app.staticTexts[Self.description].firstMatch, "Issue additional card sheet description should be displayed")
            waitAndAssertTrue(app.staticTexts[Self.feeLabel].firstMatch, "Issue fee label should be displayed")
            waitAndAssertTrue(app.staticTexts[feeValue].firstMatch, "Issue fee value '\(feeValue)' should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyUnableToCoverFee() -> Self {
        XCTContext.runActivity(named: "Verify issue additional card sheet shows 'Unable to cover fee' state") { _ in
            waitAndAssertTrue(app.staticTexts[Self.unableToCoverFeeTitle].firstMatch, "'Unable to cover fee' title should be displayed")
            waitAndAssertTrue(app.staticTexts[Self.unableToCoverFeeMessage].firstMatch, "'Unable to cover fee' message should be displayed")
            waitAndAssertTrue(addFundsButton, "Add funds button should be displayed")
            addFundsButton.waitForState(state: .enabled)
            return self
        }
    }

    @discardableResult
    func verifyIssueCardEnabled() -> Self {
        XCTContext.runActivity(named: "Verify Issue card button is enabled") { _ in
            waitAndAssertTrue(issueCardButton, "Issue card button should be displayed")
            issueCardButton.waitForState(state: .enabled)
            return self
        }
    }

    @discardableResult
    func verifyIssueCardDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Issue card button is disabled") { _ in
            waitAndAssertTrue(issueCardButton, "Issue card button should be displayed")
            issueCardButton.waitForState(state: .disabled)
            return self
        }
    }

    @discardableResult
    func tapIssueCard() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Tap Issue card on issue additional card sheet") { _ in
            issueCardButton.waitAndTap()
            XCTAssertTrue(
                issueCardButton.waitForNonExistence(timeout: .robustUIUpdate),
                "Issue additional card sheet should be dismissed after confirming"
            )
            return TangemPayMainScreen(app)
        }
    }

    @discardableResult
    func tapAddFunds() -> TangemPayAddFundsSheet {
        XCTContext.runActivity(named: "Tap Add funds on 'Unable to cover fee' issue additional card sheet") { _ in
            addFundsButton.waitAndTap()
            return TangemPayAddFundsSheet(app)
        }
    }
}
