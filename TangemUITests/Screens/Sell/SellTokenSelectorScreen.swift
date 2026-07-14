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
    private lazy var closeButton = button(.closeButton)
    private lazy var searchField = searchField(.searchField)
    private lazy var screenRoot = scrollView(.screenRoot)

    @discardableResult
    func waitSellTokenSelectorDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Sell Token Selector screen is displayed") { _ in
            waitAndAssertTrue(screenRoot, "Sell Token Selector screen should be displayed")
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

    func tapToken(_ label: String) -> TransferSheetScreen {
        XCTContext.runActivity(named: "Tap token with label: \(label)") { _ in
            let tokenItem = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: label)].firstMatch
            waitAndAssertTrue(tokenItem, "Token \(label) should exist in Sell Token Selector")
            tokenItem.waitAndTap()
            return TransferSheetScreen(app)
        }
    }
}

enum SellTokenSelectorScreenElement: String, UIElement {
    case closeButton
    case searchField
    case screenRoot

    var accessibilityIdentifier: String {
        switch self {
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        case .searchField:
            return "Search"
        case .screenRoot:
            return ActionButtonsAccessibilityIdentifiers.sellTokenSelectorScreen
        }
    }
}
