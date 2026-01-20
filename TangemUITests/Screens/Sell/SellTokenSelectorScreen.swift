//
//  SellTokenSelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SellTokenSelectorScreen: ScreenBase<SellTokenSelectorScreenElement> {
    private lazy var titleLabel = app.navigationBars.staticTexts["Sell"]
    private lazy var closeButton = button(.closeButton)
    private lazy var searchField = searchField(.searchField)

    @discardableResult
    func waitSellTokenSelectorDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Sell Token Selector screen is displayed") { _ in
            waitAndAssertTrue(titleLabel, "Sell Token Selector screen title should exist")
            waitAndAssertTrue(closeButton, "Close button should exist")
            waitAndAssertTrue(searchField, "Search field should exist")
        }
        return self
    }

    @discardableResult
    func tapCloseButton() -> MainScreen {
        XCTContext.runActivity(named: "Close Sell Token Selector screen") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist on Sell Token Selector screen")
            closeButton.waitAndTap()
            return MainScreen(app)
        }
    }
}

enum SellTokenSelectorScreenElement: String, UIElement {
    case closeButton
    case searchField

    var accessibilityIdentifier: String {
        switch self {
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        case .searchField:
            return "Search"
        }
    }
}
