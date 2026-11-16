//
//  PolymarketAddFundsSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import XCTest
import TangemAccessibilityIdentifiers

final class PolymarketAddFundsSheet: Screen {
    let app: XCUIApplication

    private lazy var swapOption = app.descendants(matching: .any)
        .matching(identifier: PolymarketAccessibilityIdentifiers.addFundsSheetSwapOption)
        .firstMatch
    private lazy var receiveOption = app.descendants(matching: .any)
        .matching(identifier: PolymarketAccessibilityIdentifiers.addFundsSheetReceiveOption)
        .firstMatch
    private lazy var closeButton = app.buttons[Localization.commonClose].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyOptionsDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the 'Swap' and 'Receive' options are displayed") { _ in
            waitAndAssertTrue(swapOption, timeout: .networkRequest, "'Swap' option should be displayed")
            waitAndAssertTrue(receiveOption, timeout: .networkRequest, "'Receive' option should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyOptionsNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the 'Add funds' options are not displayed") { _ in
            XCTAssertTrue(swapOption.staysAbsent(for: .absenceCheck), "'Swap' option should not be displayed")
            XCTAssertFalse(receiveOption.exists, "'Receive' option should not be displayed")
            return self
        }
    }

    @discardableResult
    func close() -> PolymarketMainScreen {
        XCTContext.runActivity(named: "Close the 'Add funds' sheet") { _ in
            XCTAssertTrue(closeButton.waitAndTap(), "Close button should be tappable")
            return PolymarketMainScreen(app)
        }
    }
}
