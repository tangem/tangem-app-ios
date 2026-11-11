//
//  PolymarketWithdrawScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class PolymarketWithdrawScreen: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[SendAccessibilityIdentifiers.sendViewTitle].firstMatch
    private lazy var closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the Polymarket withdraw screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Polymarket withdraw screen should be displayed")
            XCTAssertEqual(title.label, Localization.predictionMainWithdraw, "Withdraw screen should show its title")
            return self
        }
    }

    @discardableResult
    func close() -> PolymarketMainScreen {
        XCTContext.runActivity(named: "Close the Polymarket withdraw screen") { _ in
            XCTAssertTrue(closeButton.waitAndTap(), "Close button should be tappable")
            return PolymarketMainScreen(app)
        }
    }
}
