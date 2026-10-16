//
//  SwapTokenSelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SwapTokenSelectorScreen: ScreenBase<SwapTokenSelectorScreenElement> {
    private lazy var titleLabel = app.navigationBars.staticTexts["Choose token"]
    private lazy var closeButton = button(.closeButton)
    private lazy var searchField = searchField(.searchField)
    private lazy var clearSearchButton = searchField.buttons["Clear text"].firstMatch
    private lazy var balanceFilterChip = button(.balanceFilterChip)
    private lazy var filteredOutEmptyMessage = staticText(.filteredOutEmptyMessage)
    private lazy var seeAllButton = button(.seeAllButton)

    @discardableResult
    func waitSwapTokenSelectorDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Swap Token Selector screen is displayed") { _ in
            waitAndAssertTrue(titleLabel, "Swap Token Selector screen title should exist")
            waitAndAssertTrue(closeButton, "Close button should exist")
            waitAndAssertTrue(searchField, "Search field should exist")
        }
        return self
    }

    @discardableResult
    func selectToken(_ tokenName: String) -> SwapScreen {
        XCTContext.runActivity(named: "Select token '\(tokenName)' from token selector") { _ in
            waitAndAssertTrue(searchField, "Token selector search field should be visible")

            let tokenCell = tokenItemButton(name: tokenName)
            waitAndAssertTrue(tokenCell, "Token '\(tokenName)' should be visible in token selector list")
            tokenCell.waitAndTap()
            return SwapScreen(app)
        }
    }

    @discardableResult
    func tapCloseButton() -> MainScreen {
        XCTContext.runActivity(named: "Close Swap Token Selector screen") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist on Swap Token Selector screen")
            closeButton.waitAndTap()
            return MainScreen(app)
        }
    }

    @discardableResult
    func tapCloseAndReturnToSwap() -> SwapScreen {
        XCTContext.runActivity(named: "Close Swap Token Selector screen and return to Swap") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist on Swap Token Selector screen")
            closeButton.waitAndTap()
            return SwapScreen(app)
        }
    }

    @discardableResult
    func typeSearchText(_ text: String) -> Self {
        XCTContext.runActivity(named: "Type '\(text)' in search field") { _ in
            typeWithFocus(into: searchField, text: text)
        }
        return self
    }

    @discardableResult
    func clearSearchText() -> Self {
        XCTContext.runActivity(named: "Clear search field text") { _ in
            waitAndAssertTrue(searchField, "Search field should exist")
            clearSearchButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForTokenDisplayed(_ name: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(name)' is displayed in token selector") { _ in
            let tokenElement = tokenItemButton(name: name)
            waitAndAssertTrue(tokenElement, "Token '\(name)' should be displayed in token selector list")
        }
        return self
    }

    @discardableResult
    func waitForTokenAvailable(_ name: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(name)' is displayed and available for swap") { _ in
            let tokenElement = tokenItemButton(name: name)
            waitAndAssertTrue(tokenElement, "Token '\(name)' should be displayed in token selector list")
            XCTAssertTrue(tokenElement.isEnabled, "Token '\(name)' should be enabled (available for swap)")
        }
        return self
    }

    @discardableResult
    func waitForTokenNotDisplayed(_ name: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(name)' is NOT displayed in token selector") { _ in
            let tokenElement = tokenItemButton(name: name)
            XCTAssertTrue(tokenElement.waitForNonExistence(timeout: .quick), "Token '\(name)' should NOT be displayed in token selector list")
        }
        return self
    }

    @discardableResult
    func waitForTokenUnavailable(_ name: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(name)' is displayed but unavailable") { _ in
            let tokenElement = tokenItemButton(name: name)
            waitAndAssertTrue(tokenElement, "Token '\(name)' should be displayed in token selector list")
            XCTAssertFalse(tokenElement.isEnabled, "Token '\(name)' should be displayed but not enabled (unavailable)")
        }
        return self
    }

    @discardableResult
    func assertTokenOrder(_ names: [String]) -> Self {
        XCTContext.runActivity(named: "Verify token order: \(names)") { _ in
            let positions = names.map { name -> CGFloat in
                let element = tokenItemButton(name: name)
                waitAndAssertTrue(element, "Token '\(name)' should be displayed in token selector list")
                return element.frame.minY
            }
            let isOrdered = zip(positions, positions.dropFirst()).allSatisfy { $0 < $1 }
            XCTAssertTrue(isOrdered, "Tokens should be listed in order \(names), but their on-screen positions were \(positions)")
        }
        return self
    }

    /// Selects a FROM token and stays on the token selector (transitions to TO token selection)
    @discardableResult
    func selectFromToken(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Select FROM token '\(tokenName)' from token selector") { _ in
            waitAndAssertTrue(searchField, "Token selector search field should be visible")

            let tokenCell = tokenItemButton(name: tokenName)
            waitAndAssertTrue(tokenCell, "Token '\(tokenName)' should be visible in token selector list")
            tokenCell.waitAndTap()
        }
        return self
    }

    // MARK: - Market Tokens

    @discardableResult
    func selectMarketToken(_ name: String) -> AddTokenFlowScreen {
        XCTContext.runActivity(named: "Select market token '\(name)' from search results") { _ in
            let marketTokenCell = marketTokenItemButton(name: name)
            marketTokenCell.waitAndTap()
            return AddTokenFlowScreen(app)
        }
    }

    @discardableResult
    func waitForMarketTokenDisplayed(_ name: String) -> Self {
        XCTContext.runActivity(named: "Verify market token '\(name)' is displayed in search results") { _ in
            let marketTokenCell = marketTokenItemButton(name: name)
            waitAndAssertTrue(marketTokenCell, "Market token '\(name)' should be displayed in search results")
        }
        return self
    }

    @discardableResult
    func verifyTokenCount(_ expected: Int) -> Self {
        XCTContext.runActivity(named: "Verify the token selector lists \(expected) tokens") { _ in
            let query = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", CommonUIAccessibilityIdentifiers.tokenSelectorItemPrefix)
            )
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "count == %d", expected),
                object: query
            )
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Token selector should list \(expected) tokens, but listed \(query.count)"
            )
        }
        return self
    }

    // MARK: - Balance filter

    @discardableResult
    func waitBalanceFilterChipLabel(contains text: String) -> Self {
        XCTContext.runActivity(named: "Verify balance filter chip label contains '\(text)'") { _ in
            waitAndAssertTrue(balanceFilterChip, "Balance filter chip should exist")
            let predicate = NSPredicate(format: "label CONTAINS %@", text)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: balanceFilterChip)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Balance filter chip label should contain '\(text)' but was '\(balanceFilterChip.label)'"
            )
        }
        return self
    }

    @discardableResult
    func selectBalanceFilter(_ option: TokenSelectorBalanceFilterOption) -> Self {
        XCTContext.runActivity(named: "Select '\(option.rawValue)' balance filter") { _ in
            waitAndAssertTrue(balanceFilterChip, "Balance filter chip should exist")
            balanceFilterChip.waitAndTap()

            let optionButton = app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorBalanceFilterOption(option.rawValue)].firstMatch
            waitAndAssertTrue(optionButton, "Balance filter option '\(option.rawValue)' should be visible")
            optionButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForFilteredOutEmptyMessageDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify filtered-out empty message is displayed") { _ in
            waitAndAssertTrue(filteredOutEmptyMessage, "Filtered-out empty message should be displayed")
            waitAndAssertTrue(seeAllButton, "'See all' button should be displayed")
        }
        return self
    }

    @discardableResult
    func tapSeeAllButton() -> Self {
        XCTContext.runActivity(named: "Tap 'See all' button") { _ in
            waitAndAssertTrue(seeAllButton, "'See all' button should exist")
            seeAllButton.waitAndTap()
        }
        return self
    }

    // MARK: - Error State

    @discardableResult
    func waitForTrendingNowError() -> Self {
        XCTContext.runActivity(named: "Verify Trending Now section shows error state") { _ in
            let retryButton = app.buttons[CommonUIAccessibilityIdentifiers.retryButton].firstMatch
            waitAndAssertTrue(retryButton, "Trending Now error state should be displayed with retry button")
        }
        return self
    }

    @discardableResult
    func waitForRetryButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify 'Try again' button is displayed") { _ in
            let retryButton = app.buttons[CommonUIAccessibilityIdentifiers.retryButton].firstMatch
            waitAndAssertTrue(retryButton, "'Try again' button should be displayed")
        }
        return self
    }

    // MARK: - Private

    private func tokenItemButton(name: String) -> XCUIElement {
        app.buttons[CommonUIAccessibilityIdentifiers.tokenSelectorItem(name: name)].firstMatch
    }

    private func marketTokenItemButton(name: String) -> XCUIElement {
        app.buttons[MarketsAccessibilityIdentifiers.marketsListTokenItem(uniqueId: name)].firstMatch
    }
}

enum SwapTokenSelectorScreenElement: String, UIElement {
    case closeButton
    case searchField
    case balanceFilterChip
    case filteredOutEmptyMessage
    case seeAllButton

    var accessibilityIdentifier: String {
        switch self {
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        case .searchField:
            return "Search"
        case .balanceFilterChip:
            return CommonUIAccessibilityIdentifiers.tokenSelectorBalanceFilterChip
        case .filteredOutEmptyMessage:
            return SwapAccessibilityIdentifiers.tokenSelectorFilteredOutEmptyMessage
        case .seeAllButton:
            return SwapAccessibilityIdentifiers.tokenSelectorSeeAllButton
        }
    }
}

enum TokenSelectorBalanceFilterOption: String {
    case all
    case hideZero
}
