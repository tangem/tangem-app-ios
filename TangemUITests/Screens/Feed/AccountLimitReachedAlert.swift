//
//  AccountLimitReachedAlert.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class AccountLimitReachedAlert: Screen {
    let app: XCUIApplication

    private lazy var limitAlert = app.alerts.firstMatch
    private lazy var limitMessage = app.alerts.staticTexts
        .matching(NSPredicate(format: "label CONTAINS %@", Constants.messageFragment))
        .firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify account limit reached popup is displayed") { _ in
            waitAndAssertTrue(limitAlert, "Account limit reached popup should be displayed")
            waitAndAssertTrue(limitMessage, "Account limit popup should show the limit message")
            return self
        }
    }
}

private extension AccountLimitReachedAlert {
    enum Constants {
        static let messageFragment = "Archive one to add new"
    }
}
