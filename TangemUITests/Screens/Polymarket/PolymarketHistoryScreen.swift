//
//  PolymarketHistoryScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import XCTest

final class PolymarketHistoryScreen: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[Localization.predictionHistoryTitle].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Polymarket history screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Polymarket history screen should be displayed")
            return self
        }
    }

    @discardableResult
    func goBack() -> PolymarketMainScreen {
        tapBackButton(to: PolymarketMainScreen.self)
    }
}
