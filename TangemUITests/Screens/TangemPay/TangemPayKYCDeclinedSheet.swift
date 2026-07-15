//
//  TangemPayKYCDeclinedSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayKYCDeclinedSheet: Screen {
    let app: XCUIApplication

    private lazy var primaryButton = app.buttons[TangemPayAccessibilityIdentifiers.kycDeclinedSheetPrimaryButton].firstMatch
    private lazy var title = app.staticTexts["Rejected"].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for KYC rejected sheet") { _ in
            waitAndAssertTrue(primaryButton, "KYC rejected sheet primary button should be displayed")
            waitAndAssertTrue(title, "KYC rejected sheet title should be displayed")
            return self
        }
    }
}
