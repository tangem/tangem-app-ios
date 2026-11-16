//
//  PolymarketPositionDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import XCTest

final class PolymarketPositionDetailsScreen: Screen {
    let app: XCUIApplication

    private lazy var buyButton = app.buttons[Localization.commonBuy].firstMatch
    private lazy var cashOutButton = app.buttons[Localization.predictionCashOut].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyBuyEnabled() -> Self {
        XCTContext.runActivity(named: "Verify the 'Buy' button of the position is enabled") { _ in
            waitAndAssertTrue(buyButton, timeout: .networkRequest, "'Buy' button should be displayed")
            XCTAssertTrue(buyButton.isEnabled, "'Buy' button should be enabled")
            return self
        }
    }

    @discardableResult
    func verifyBuyDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the position screen is displayed") { _ in
            waitAndAssertTrue(buyButton, timeout: .networkRequest, "Position screen should be displayed")
            return self
        }
    }

    @discardableResult
    func tapBuy() -> PolymarketOrderSheet {
        XCTContext.runActivity(named: "Tap the 'Buy' button of the position") { _ in
            XCTAssertTrue(buyButton.waitAndTap(), "'Buy' button should be tappable")
            return PolymarketOrderSheet(app, intent: .buy)
        }
    }

    @discardableResult
    func tapCashOut() -> PolymarketOrderSheet {
        XCTContext.runActivity(named: "Tap the 'Cash Out' button of the position") { _ in
            XCTAssertTrue(cashOutButton.waitAndTap(), "'Cash Out' button should be tappable")
            return PolymarketOrderSheet(app, intent: .sell)
        }
    }

    @discardableResult
    func goBack() -> PolymarketMainScreen {
        tapBackButton(to: PolymarketMainScreen.self)
    }
}
