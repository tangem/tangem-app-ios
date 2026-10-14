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
    func verifyDate(_ date: Date) -> Self {
        XCTContext.runActivity(named: "Verify the success screen shows \(date)") { _ in
            let formatter = DateFormatter()
            formatter.locale = UITestLocale.locale
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            let dateText = formatter.string(from: date)
            let predicate = NSPredicate(format: "label CONTAINS %@", dateText)
            waitAndAssertTrue(app.staticTexts.matching(predicate).firstMatch, "Success screen should show the date '\(dateText)'")
            return self
        }
    }

    @discardableResult
    func verifyDetail(title: String, value: String) -> Self {
        XCTContext.runActivity(named: "Verify the success screen shows \(title): \(value)") { _ in
            let predicate = NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", title, value)
            waitAndAssertTrue(app.descendants(matching: .any).matching(predicate).firstMatch, "Success screen should show \(title) '\(value)'")
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
