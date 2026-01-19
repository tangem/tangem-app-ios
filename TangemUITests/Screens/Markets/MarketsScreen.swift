//
//  MarketsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsScreen: ScreenBase<MarketsScreenElement> {
    private lazy var searchField = textField(.searchThroughMarketField)
    private lazy var searchFieldClearButton = app.buttons[MainAccessibilityIdentifiers.searchThroughMarketClearButton]
    private lazy var addToPortfolioButton = button(.addToPortfolioButton)
    private lazy var mainNetworkSwitch = switchElement(.mainNetworkSwitch)
    private lazy var continueButton = button(.continueButton)
    private lazy var tokensUnderCapExpandButton = button(.marketsTokensUnderCapExpandButton)
    private lazy var noResultsLabel = staticText(.marketsSearchNoResultsLabel)

    @discardableResult
    func closeMarketsSheetWithSwipe() -> MainScreen {
        XCTContext.runActivity(named: "Close markets sheet with swipe down gesture") { _ in
            // Find the grabber view or bottom sheet area to swipe down
            let grabberView = app.otherElements.matching(identifier: "commonUIGrabber").firstMatch

            waitAndAssertTrue(grabberView)

            // Swipe down on the grabber view
            let startPoint = grabberView.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let endPoint = startPoint.withOffset(CGVector(dx: 0, dy: 400)) // Swipe down 300 points
            startPoint.press(forDuration: 0.1, thenDragTo: endPoint)

            return MainScreen(app)
        }
    }

    @discardableResult
    func searchForToken(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Search for token: \(tokenName)") { _ in
            searchField.waitAndTap()
            searchField.typeText(tokenName)
            return self
        }
    }

    @discardableResult
    func tapTokenInSearchResults(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Tap token in search results: \(tokenName)") { _ in
            let tokenButton = app.buttons[
                MarketsAccessibilityIdentifiers.marketsListTokenItem(uniqueId: tokenName)
            ]
            waitAndAssertTrue(tokenButton, "Token button should exist")
            tokenButton.tap()
            return self
        }
    }

    @discardableResult
    func openTokenDetails(_ tokenName: String) -> MarketsTokenDetailsScreen {
        tapTokenInSearchResults(tokenName)
        return MarketsTokenDetailsScreen(app)
    }

    @discardableResult
    func tapAddToPortfolioButton() -> Self {
        XCTContext.runActivity(named: "Tap Add to Portfolio button") { _ in
            XCTAssertTrue(
                addToPortfolioButton.waitForExistence(timeout: .robustUIUpdate),
                "Add to Portfolio button should exist"
            )
            addToPortfolioButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func toggleMainNetworkSwitch() -> Self {
        XCTContext.runActivity(named: "Toggle MAIN network switch") { _ in
            XCTAssertTrue(
                mainNetworkSwitch.waitForExistence(timeout: .robustUIUpdate),
                "MAIN network switch should exist"
            )
            mainNetworkSwitch.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapContinueButton() -> Self {
        XCTContext.runActivity(named: "Tap Continue button") { _ in
            XCTAssertTrue(
                continueButton.waitForExistence(timeout: .robustUIUpdate),
                "Continue button should exist"
            )
            continueButton.waitAndTap()
            return self
        }
    }

    func tapBackButton() -> Self {
        XCTContext.runActivity(named: "Tap Back button") { _ in
            app.buttons["Back"].waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyAllVisibleSearchResultsCurrencyContains(_ substring: String) -> Self {
        XCTContext.runActivity(named: "Verify all visible search results currency contains: \(substring)") { _ in
            let currencyLabels = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.marketsListTokenCurrencyLabel
            )

            waitAndAssertTrue(currencyLabels.firstMatch, "Search results currency labels should exist")

            let count = currencyLabels.count
            XCTAssertGreaterThan(count, 0, "Search results currency labels count should be > 0")

            for index in 0 ..< count {
                let label = currencyLabels.element(boundBy: index)
                let value = label.label
                XCTAssertFalse(value.isEmpty, "Currency label at index \(index) should not be empty")
                XCTAssertTrue(
                    value.localizedCaseInsensitiveContains(substring),
                    "Currency label '\(value)' should contain '\(substring)'"
                )
            }

            return self
        }
    }

    @discardableResult
    func verifyAllVisibleSearchResultsTokenNameContains(_ substring: String) -> Self {
        XCTContext.runActivity(named: "Verify all visible search results contain: \(substring) (name or currency)") { _ in
            let nameLabels = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.marketsListTokenNameLabel
            )
            let currencyLabels = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.marketsListTokenCurrencyLabel
            )

            waitAndAssertTrue(nameLabels.firstMatch, "At least one search result token name label should exist")

            let namesCount = nameLabels.count
            XCTAssertGreaterThan(namesCount, 0, "Search results token name labels count should be > 0")

            let currencyCount = currencyLabels.count

            for index in 0 ..< namesCount {
                let nameElement = nameLabels.element(boundBy: index)
                let nameValue = nameElement.label
                XCTAssertFalse(nameValue.isEmpty, "Token name label at index \(index) should not be empty")

                if nameValue.localizedCaseInsensitiveContains(substring) {
                    continue
                }

                // Fallback: validate by currency/ticker (e.g., when searching by ticker-like substring).
                if index < currencyCount {
                    let currencyElement = currencyLabels.element(boundBy: index)
                    let currencyValue = currencyElement.label
                    XCTAssertFalse(currencyValue.isEmpty, "Currency label at index \(index) should not be empty")

                    XCTAssertTrue(
                        currencyValue.localizedCaseInsensitiveContains(substring),
                        "Search result at index \(index) should contain '\(substring)' either in name ('\(nameValue)') or currency ('\(currencyValue)')"
                    )
                } else {
                    XCTFail(
                        "Search result at index \(index) should contain '\(substring)' in name ('\(nameValue)'), but currency label is missing"
                    )
                }
            }

            return self
        }
    }

    @discardableResult
    func tapShowTokensUnderCapButton() -> Self {
        XCTContext.runActivity(named: "Tap 'Show tokens' under cap button") { _ in
            tokensUnderCapExpandButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyNoResultsStateIsDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Markets search no results state is displayed") { _ in
            waitAndAssertTrue(noResultsLabel, "No results label should be visible")
            return self
        }
    }

    @discardableResult
    func pasteIntoSearchField() -> Self {
        XCTContext.runActivity(named: "Paste into Markets search field") { _ in
            searchField.waitAndTap()
            searchField.press(forDuration: 1.0)

            let pasteMenuItem = app.menuItems["Paste"]
            pasteMenuItem.waitAndTap()

            return self
        }
    }

    @discardableResult
    func verifyTokenInSearchResults(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify token in search results: \(tokenName)") { _ in
            let tokenButton = app.buttons[
                MarketsAccessibilityIdentifiers.marketsListTokenItem(uniqueId: tokenName)
            ]
            waitAndAssertTrue(tokenButton, "Expected \(tokenName) to be present in Markets search results")
            return self
        }
    }

    @discardableResult
    func verifyFirstCoinsOrder(_ expected: [String]) -> Self {
        XCTContext.runActivity(named: "Verify first coins order") { _ in
            let nameLabels = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.marketsListTokenNameLabel
            )
            waitAndAssertTrue(nameLabels.firstMatch, "Markets token name labels should exist")

            let actual = nameLabels.allElementsBoundByIndex.prefix(expected.count).map { $0.label }
            XCTAssertEqual(actual, expected, "First coins order doesn't match expected")

            return self
        }
    }

    @discardableResult
    func tapSearchFieldAndVerifyKeyboard() -> Self {
        XCTContext.runActivity(named: "Tap Markets search field and verify keyboard") { _ in
            searchField.waitAndTap()
            waitAndAssertTrue(app.keyboards.firstMatch, "Keyboard should appear after tapping search field")
            return self
        }
    }

    @discardableResult
    func typeInSearchField(_ text: String) -> Self {
        XCTContext.runActivity(named: "Type in Markets search field: \(text)") { _ in
            waitAndAssertTrue(searchField, "Markets search field should exist")
            searchField.typeText(text)
            return self
        }
    }

    @discardableResult
    func deleteSearchCharacters(_ count: Int) -> Self {
        XCTContext.runActivity(named: "Delete \(count) characters from Markets search field") { _ in
            guard count > 0 else { return self }

            let deleteKey = app.keys["delete"]
            XCTAssertTrue(deleteKey.waitForExistence(timeout: .robustUIUpdate), "Delete key should exist")

            for _ in 0 ..< count {
                deleteKey.tap()
            }

            return self
        }
    }

    @discardableResult
    func clearSearchField() -> Self {
        XCTContext.runActivity(named: "Clear Markets search field") { _ in
            searchFieldClearButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifySearchFieldIsEmptyAndClearButtonHidden() -> Self {
        XCTContext.runActivity(named: "Verify Markets search field is empty and clear button hidden") { _ in
            waitAndAssertTrue(searchField, "Markets search field should exist")
            XCTAssertTrue(searchField.value as? String == "" || searchField.label.isEmpty, "Search field should be empty")
            XCTAssertTrue(
                searchFieldClearButton.waitForState(state: .notHittable),
                "Clear button should not be visible when search field is empty"
            )

            return self
        }
    }
}

enum MarketsScreenElement: String, UIElement {
    case searchThroughMarketField
    case addToPortfolioButton
    case mainNetworkSwitch
    case continueButton
    case marketsTokensUnderCapExpandButton
    case marketsSearchNoResultsLabel

    var accessibilityIdentifier: String {
        switch self {
        case .searchThroughMarketField:
            MainAccessibilityIdentifiers.searchThroughMarketField
        case .addToPortfolioButton:
            MainAccessibilityIdentifiers.addToPortfolioButton
        case .mainNetworkSwitch:
            TokenAccessibilityIdentifiers.mainNetworkSwitch
        case .continueButton:
            TokenAccessibilityIdentifiers.continueButton
        case .marketsTokensUnderCapExpandButton:
            MarketsAccessibilityIdentifiers.marketsTokensUnderCapExpandButton
        case .marketsSearchNoResultsLabel:
            MarketsAccessibilityIdentifiers.marketsSearchNoResultsLabel
        }
    }
}
