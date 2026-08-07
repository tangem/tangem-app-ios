//
//  TokenScreen+Yield.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

extension TokenScreen {
    private var activeYieldBlock: XCUIElement {
        app.buttons[YieldModuleAccessibilityIdentifiers.activeBlock].firstMatch
    }

    private var earnBlockTitleIcon: XCUIElement {
        app.descendants(matching: .any)[YieldModuleAccessibilityIdentifiers.earnBlockTitleIcon].firstMatch
    }

    private var availableYieldEntry: XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier == %@ OR identifier == %@",
                YieldModuleAccessibilityIdentifiers.availableBlock,
                CommonUIAccessibilityIdentifiers.yieldModuleNotificationButton
            )
        ).firstMatch
    }

    @discardableResult
    func waitForAvailableYieldBlock() -> Self {
        XCTContext.runActivity(named: "Wait for available yield block") { _ in
            waitAndAssertTrue(availableYieldEntry, "Available yield block should be displayed")
            return self
        }
    }

    @discardableResult
    func tapAvailableYieldBlock() -> YieldModulePromoScreen {
        XCTContext.runActivity(named: "Tap available yield block") { _ in
            availableYieldEntry.waitAndTap()
            return YieldModulePromoScreen(app)
        }
    }

    @discardableResult
    func waitForYieldEnabledBlock() -> Self {
        XCTContext.runActivity(named: "Wait for 'Yield mode enabled' block") { _ in
            waitAndAssertTrue(activeYieldBlock, "'Yield mode enabled' block should be displayed")
            return self
        }
    }

    @discardableResult
    func tapYieldEnabledBlock() -> YieldModuleActiveScreen {
        XCTContext.runActivity(named: "Tap 'Yield mode enabled' block") { _ in
            activeYieldBlock.waitAndTap()
            return YieldModuleActiveScreen(app)
        }
    }

    @discardableResult
    func assertYieldApyDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert yield block shows an APY value") { _ in
            waitAndAssertTrue(activeYieldBlock, "'Yield mode enabled' block should be displayed")
            XCTAssertTrue(
                activeYieldBlock.label.contains("APY"),
                "Yield block should show an APY value but label was '\(activeYieldBlock.label)'"
            )
            return self
        }
    }

    @discardableResult
    func assertYieldInfoIconVisible() -> Self {
        XCTContext.runActivity(named: "Assert yield block info icon is displayed") { _ in
            waitAndAssertTrue(earnBlockTitleIcon, "Yield block info icon should be displayed")
            return self
        }
    }

    @discardableResult
    func assertYieldInfoIconHidden() -> Self {
        XCTContext.runActivity(named: "Assert yield block info icon is not displayed") { _ in
            XCTAssertTrue(
                earnBlockTitleIcon.waitForNonExistence(timeout: .conditional),
                "Yield block info icon should not be displayed"
            )
            return self
        }
    }
}
