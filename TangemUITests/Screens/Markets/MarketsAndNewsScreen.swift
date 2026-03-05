//
//  MarketsAndNewsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsAndNewsScreen: ScreenBase<MarketsAndNewsScreenElement> {
    private lazy var seeAllButton = button(.seeAllButton)
    private lazy var searchField = textField(.searchThroughMarketField)

    @discardableResult
    func tapSeeAll() -> MarketsScreen {
        XCTContext.runActivity(named: "Tap See All button to open Markets screen") { _ in
            waitAndAssertTrue(seeAllButton, "See All button should be displayed")
            seeAllButton.waitAndTap()
            return MarketsScreen(app)
        }
    }

    @discardableResult
    func searchForToken(_ tokenName: String) -> MarketsScreen {
        XCTContext.runActivity(named: "Search for token: \(tokenName)") { _ in
            searchField.waitAndTap()
            searchField.typeText(tokenName)
            return MarketsScreen(app)
        }
    }

    @discardableResult
    func pasteIntoSearchField() -> MarketsScreen {
        XCTContext.runActivity(named: "Paste into Markets search field") { _ in
            searchField.waitAndTap()
            searchField.press(forDuration: 1.0)

            let pasteMenuItem = app.menuItems["Paste"]
            pasteMenuItem.waitAndTap()

            return MarketsScreen(app)
        }
    }

    @discardableResult
    func tapSearchFieldAndVerifyKeyboard() -> MarketsScreen {
        XCTContext.runActivity(named: "Tap Markets search field and verify keyboard") { _ in
            searchField.waitAndTap()
            waitAndAssertTrue(app.keyboards.firstMatch, "Keyboard should appear after tapping search field")
            return MarketsScreen(app)
        }
    }

    @discardableResult
    func typeInSearchField(_ text: String) -> MarketsScreen {
        XCTContext.runActivity(named: "Type in Markets search field: \(text)") { _ in
            waitAndAssertTrue(searchField, "Markets search field should exist")
            searchField.typeText(text)
            return MarketsScreen(app)
        }
    }

    @discardableResult
    func verifyMarketsSheetIsDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Markets sheet is displayed") { _ in
            waitAndAssertTrue(searchField, "Markets sheet should be displayed with search field")
            return self
        }
    }
}

enum MarketsAndNewsScreenElement: String, UIElement {
    case seeAllButton
    case searchThroughMarketField

    var accessibilityIdentifier: String {
        switch self {
        case .seeAllButton:
            return MarketsAccessibilityIdentifiers.marketsSeeAllButton
        case .searchThroughMarketField:
            return MainAccessibilityIdentifiers.searchThroughMarketField
        }
    }
}
