//
//  TangemPayNoDepositAddressSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayNoDepositAddressSheet: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for 'Service temporarily unavailable' sheet") { _ in
            waitAndAssertTrue(app.staticTexts[Localization.tangempayServiceUnavailableTitle].firstMatch, "Error title should be displayed")
            waitAndAssertTrue(app.staticTexts[Localization.tangempayCardDetailsReceiveErrorDescription].firstMatch, "Error description should be displayed")
            waitAndAssertTrue(app.buttons[Localization.commonGotIt].firstMatch, "Got it button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapGotIt() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Tap Got it and verify sheet is dismissed") { _ in
            app.buttons[Localization.commonGotIt].firstMatch.waitAndTap()
            XCTAssertTrue(
                app.staticTexts[Localization.tangempayServiceUnavailableTitle].firstMatch.waitForNonExistence(timeout: .robustUIUpdate),
                "'Service temporarily unavailable' sheet should be dismissed"
            )
            return TangemPayMainScreen(app)
        }
    }
}
