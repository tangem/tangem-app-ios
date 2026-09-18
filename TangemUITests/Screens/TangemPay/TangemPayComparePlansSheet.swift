//
//  TangemPayComparePlansSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayComparePlansSheet: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet(comparing planName: String) -> Self {
        XCTContext.runActivity(named: "Wait for Compare plans sheet") { _ in
            waitAndAssertTrue(planRow(planName), timeout: .networkRequest, "Compare plans sheet should be displayed")
            return self
        }
    }

    @discardableResult
    func verifySection(_ title: String) -> Self {
        XCTContext.runActivity(named: "Verify the '\(title)' comparison section is displayed") { _ in
            let section = app.staticTexts[TangemPayAccessibilityIdentifiers.comparePlansSection(title)].firstMatch
            waitAndAssertTrue(section, "The '\(title)' comparison section should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyPlanCompared(_ planName: String) -> Self {
        XCTContext.runActivity(named: "Verify the '\(planName)' plan is compared") { _ in
            waitAndAssertTrue(planRow(planName), "The '\(planName)' plan should have a row in the comparison")
            return self
        }
    }

    /// The sheet rows are matched by their own identifier so the screen behind the sheet cannot satisfy the check.
    private func planRow(_ planName: String) -> XCUIElement {
        app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.comparePlansRow(planName)].firstMatch
    }
}
