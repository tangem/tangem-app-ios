//
//  ReceiveTokenAlertSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class ReceiveTokenAlertSheet: Screen {
    private static let gotItButtonLabel = "Got it"

    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyDepositInfo(network: String) -> Self {
        XCTContext.runActivity(named: "Verify deposit address info for '\(network)' network") { _ in
            let networkText = app.staticTexts
                .element(matching: NSPredicate(format: "label CONTAINS %@", network))
                .firstMatch
            waitAndAssertTrue(networkText, "Deposit info should mention the '\(network)' network")
            waitAndAssertTrue(app.buttons[Self.gotItButtonLabel].firstMatch, "'Got it' button should be displayed")
            return self
        }
    }
}
