//
//  TangemPayNoDepositAddressSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayNoDepositAddressSheet: Screen {
    private static let title = "Service temporarily unavailable"
    private static let subtitle = "Technical issues detected. Please try again later or contact support."
    private static let gotItButtonLabel = "Got it"

    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for 'Service temporarily unavailable' sheet") { _ in
            waitAndAssertTrue(app.staticTexts[Self.title].firstMatch, "Error title should be displayed")
            waitAndAssertTrue(app.staticTexts[Self.subtitle].firstMatch, "Error description should be displayed")
            waitAndAssertTrue(app.buttons[Self.gotItButtonLabel].firstMatch, "Got it button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapGotIt() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Tap Got it and verify sheet is dismissed") { _ in
            app.buttons[Self.gotItButtonLabel].firstMatch.waitAndTap()
            XCTAssertTrue(
                app.staticTexts[Self.title].firstMatch.waitForNonExistence(timeout: .robustUIUpdate),
                "'Service temporarily unavailable' sheet should be dismissed"
            )
            return TangemPayMainScreen(app)
        }
    }
}
