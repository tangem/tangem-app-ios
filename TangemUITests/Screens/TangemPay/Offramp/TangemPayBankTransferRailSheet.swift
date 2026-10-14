//
//  TangemPayBankTransferRailSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayBankTransferRailSheet: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[Localization.tangempayWithdrawBankSelectRoute].firstMatch
    private lazy var options = app.buttons.matching(identifier: TangemPayOfframpAccessibilityIdentifiers.railSheetOption)

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the Select route sheet") { _ in
            waitAndAssertTrue(title, "Select route sheet should be displayed")
            waitAndAssertTrue(options.firstMatch, "Select route sheet should list routes")
            return self
        }
    }

    @discardableResult
    func verifyOption(_ rail: TangemPayBankTransferRail, isSelected: Bool) -> Self {
        XCTContext.runActivity(named: "Verify the \(rail.title) route option") { _ in
            let option = self.option(rail)
            waitAndAssertTrue(option, "\(rail.title) route should be offered")
            for text in rail.texts {
                XCTAssertTrue(option.label.contains(text), "\(rail.title) route should show '\(text)'. Actual: '\(option.label)'")
            }
            XCTAssertEqual(option.isSelected, isSelected, "\(rail.title) route should\(isSelected ? "" : " not") carry the checkmark")
            return self
        }
    }

    @discardableResult
    func verifyOptionCount(_ count: Int) -> Self {
        XCTContext.runActivity(named: "Verify the sheet lists \(count) routes") { _ in
            XCTAssertEqual(options.count, count, "Select route should list \(count) routes")
            return self
        }
    }

    @discardableResult
    func select(_ rail: TangemPayBankTransferRail) -> TangemPayBankTransferAmountScreen {
        XCTContext.runActivity(named: "Select the \(rail.title) route") { _ in
            option(rail).waitAndTap()
            XCTAssertTrue(title.waitForNonExistence(timeout: .conditional), "Select route sheet should close after the selection")
            return TangemPayBankTransferAmountScreen(app)
        }
    }

    private func option(_ rail: TangemPayBankTransferRail) -> XCUIElement {
        options.matching(NSPredicate(format: "label BEGINSWITH %@", rail.title)).firstMatch
    }
}
