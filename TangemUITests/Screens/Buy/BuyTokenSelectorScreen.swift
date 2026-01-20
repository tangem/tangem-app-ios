//
//  BuyTokenSelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class BuyTokenSelectorScreen: ScreenBase<BuyTokenSelectorScreenElement> {
    private lazy var titleLabel = app.navigationBars.staticTexts["Buy"]
    private lazy var closeButton = button(.closeButton)
    private lazy var searchField = searchField(.searchField)
    private lazy var tokensList = scrollView(.tokensList)

    @discardableResult
    func waitBuyTokenSelectorDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Buy Token Selector screen is displayed") { _ in
            waitAndAssertTrue(titleLabel, "Buy Token Selector screen title should exist")
            waitAndAssertTrue(closeButton, "Close button should exist")
            waitAndAssertTrue(searchField, "Search field should exist")
            waitAndAssertTrue(tokensList, "Tokens list should exist on Buy Token Selector screen")
        }
        return self
    }

    @discardableResult
    func tapCloseButton() -> MainScreen {
        XCTContext.runActivity(named: "Close Buy Token Selector screen") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist on Buy Token Selector screen")
            closeButton.waitAndTap()
            return MainScreen(app)
        }
    }

    func tapToken(_ label: String) -> OnrampScreen {
        XCTContext.runActivity(named: "Tap token with label: \(label)") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist on Buy Token Selector screen")
            tokensList.staticTextByLabel(label: label).waitAndTap()
            return OnrampScreen(app)
        }
    }
}

enum BuyTokenSelectorScreenElement: String, UIElement {
    case closeButton
    case searchField
    case tokensList

    var accessibilityIdentifier: String {
        switch self {
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        case .searchField:
            return "Search"
        case .tokensList:
            return ActionButtonsAccessibilityIdentifiers.buyTokenSelectorTokensList
        }
    }
}
