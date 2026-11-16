//
//  PolymarketRedeemSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import XCTest

final class PolymarketRedeemSheet: Screen {
    let app: XCUIApplication

    private lazy var claimRewardButton = app.buttons[Localization.predictionPositionResultClaimAction].firstMatch
    private lazy var closeButton = app.buttons[Localization.commonClose].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyClaimRewardDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the 'Claim reward' button is displayed") { _ in
            waitAndAssertTrue(claimRewardButton, timeout: .networkRequest, "'Claim reward' button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapClaimReward() -> Self {
        XCTContext.runActivity(named: "Tap the 'Claim reward' button") { _ in
            XCTAssertTrue(claimRewardButton.waitAndTap(), "'Claim reward' button should be tappable")
            return self
        }
    }

    @discardableResult
    func close() -> PolymarketMainScreen {
        XCTContext.runActivity(named: "Close the redeemable position") { _ in
            XCTAssertTrue(closeButton.waitAndTap(), "Close button should be tappable")
            return PolymarketMainScreen(app)
        }
    }
}
