//
//  TangemPayBankTransferSuccessScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayBankTransferSuccessScreen: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen(amount: String) -> Self {
        XCTContext.runActivity(named: "Wait for the bank transfer success screen for \(amount)") { _ in
            let title = Localization.tangempayWithdrawBankSuccessTitle(amount)
            waitAndAssertTrue(app.staticTexts[title].firstMatch, timeout: .networkRequest, "Success screen should read '\(title)'")
            return self
        }
    }

    @discardableResult
    func tapClose() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the bank transfer success screen") { _ in
            guard let closeButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonClose)).firstHittableElement() else {
                XCTFail("Success screen Close button should become hittable")
                return TangemPayMainScreen(app)
            }
            closeButton.tap()
            XCTAssertTrue(closeButton.waitForNonExistence(timeout: .conditional), "Success screen should be dismissed")
            return TangemPayMainScreen(app).waitForScreen()
        }
    }
}
