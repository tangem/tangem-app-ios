//
//  TangemPayKYCStatusSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayKYCStatusSheet: Screen {
    let app: XCUIApplication

    private lazy var primaryButton = app.buttons[TangemPayAccessibilityIdentifiers.kycStatusSheetPrimaryButton].firstMatch
    /// Redesigned sheet exposes the cross by "Close" label, legacy one by the common close identifier
    private lazy var closeButton = app.buttons.matching(
        NSPredicate(format: "identifier == %@ OR label == %@", CommonUIAccessibilityIdentifiers.closeButton, "Close")
    ).firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for KYC in progress sheet") { _ in
            waitAndAssertTrue(primaryButton, "KYC status sheet primary button should be displayed")
            return self
        }
    }

    @discardableResult
    func close() -> MainScreen {
        XCTContext.runActivity(named: "Close KYC in progress sheet") { _ in
            closeButton.waitAndTap()
            XCTAssertTrue(
                primaryButton.waitForNonExistence(timeout: .robustUIUpdate),
                "KYC status sheet should be dismissed"
            )
            return MainScreen(app)
        }
    }
}
