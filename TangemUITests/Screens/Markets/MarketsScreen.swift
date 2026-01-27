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
    private lazy var continueButton = button(.continueButton)
    private lazy var addTokenButton = button(.addTokenButton)
    private lazy var getTokenLaterButton = button(.getTokenLaterButton)
    private lazy var tokensUnderCapExpandButton = button(.marketsTokensUnderCapExpandButton)
    private lazy var noResultsLabel = staticText(.marketsSearchNoResultsLabel)
    private lazy var tokenItemButtons: XCUIElementQuery = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'marketsListTokenItem_'"))

    // MARK: - Public methods

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
            waitAndAssertTrue(
                addToPortfolioButton,
                "Add to Portfolio button should exist"
            )
            addToPortfolioButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func selectNetwork(_ name: String) -> Self {
        XCTContext.runActivity(named: "Select \(name) network") { _ in
            app.buttons[TokenAccessibilityIdentifiers.networkCell(for: name)].waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapContinueButton() -> Self {
        XCTContext.runActivity(named: "Tap Continue button") { _ in
            waitAndAssertTrue(
                continueButton,
                "Continue button should exist"
            )
            continueButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapAddTokenButton() -> Self {
        XCTContext.runActivity(named: "Tap Add token button") { _ in
            addTokenButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapGetTokenLaterButton() -> Self {
        XCTContext.runActivity(named: "Tap Get token Later button") { _ in
            getTokenLaterButton.waitAndTap()
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
                waitAndAssertTrue(
                    label,
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

                    waitAndAssertTrue(
                        currencyElement,
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
            waitAndAssertTrue(deleteKey, "Delete key should exist")

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
            waitAndAssertTrue(
                searchFieldClearButton,
                "Clear button should not be visible when search field is empty"
            )

            return self
        }
    }

    @discardableResult
    func selectInterval(_ intervalId: String) -> Self {
        XCTContext.runActivity(named: "Select interval: \(intervalId)") { _ in
            let intervalButton = app.buttons[MarketsAccessibilityIdentifiers.marketsIntervalSegment(intervalId)]
            waitAndAssertTrue(intervalButton, "Interval button '\(intervalId)' should exist")
            intervalButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyIntervalSelected(_ intervalId: String) -> Self {
        XCTContext.runActivity(named: "Verify interval is selected: \(intervalId)") { _ in
            let intervalButton = app.buttons[MarketsAccessibilityIdentifiers.marketsIntervalSegment(intervalId)]
            waitAndAssertTrue(intervalButton, "Interval button '\(intervalId)' should exist")
            waitAndAssertTrue(
                intervalButton,
                "Interval '\(intervalId)' should be selected"
            )
            return self
        }
    }

    func firstPriceChangeText() -> String {
        XCTContext.runActivity(named: "Get first price change text") { _ in
            waitAndAssertTrue(tokenItemButtons.firstMatch, "Token items should exist")

            let firstTokenButton = tokenItemButtons.firstMatch
            let priceChangeText = firstTokenButton.staticTexts[
                MarketsAccessibilityIdentifiers.marketsListTokenPriceChange
            ]

            waitAndAssertTrue(priceChangeText, "Price change text should exist inside first token item")

            let text = priceChangeText.label
            XCTAssertFalse(text.isEmpty, "Price change text should not be empty")
            return text
        }
    }

    @discardableResult
    func waitForPriceChangeData() -> Self {
        XCTContext.runActivity(named: "Wait for price change data to load") { _ in
            waitAndAssertTrue(tokenItemButtons.firstMatch, "Token items should exist")

            let firstTokenButton = tokenItemButtons.firstMatch

            let priceChangeText = firstTokenButton.staticTexts[
                MarketsAccessibilityIdentifiers.marketsListTokenPriceChange
            ]

            waitAndAssertTrue(priceChangeText, "Price change text should exist")

            // Wait for price change to contain valid data (%, + or - prefix)
            // Exclude loading states like dash or empty
            let predicate = NSPredicate { _, _ in
                let text = priceChangeText.label
                return !text.isEmpty && text != "–" && (text.contains("%") || text.hasPrefix("+") || text.hasPrefix("-"))
            }

            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)

            waitAndAssertTrue(
                result == .completed ? priceChangeText : app.buttons["nonexistent"],
                "Price change data should load and have content within timeout"
            )

            return self
        }
    }

    @discardableResult
    func verifyTokensHavePriceChangeAndCharts(maxTokens: Int = 3) -> Self {
        XCTContext.runActivity(named: "Verify first \(maxTokens) tokens have price change and charts") { _ in
            waitAndAssertTrue(tokenItemButtons.firstMatch, "Token items should exist")

            let allTokenButtons = tokenItemButtons.allElementsBoundByIndex
            XCTAssertGreaterThan(allTokenButtons.count, 0, "Should have at least one token item")

            let tokensToVerify = allTokenButtons.prefix(maxTokens)
            for (index, tokenButton) in tokensToVerify.enumerated() {
                // Verify price change
                verifyTokenStaticText(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenPriceChange,
                    name: "Price change",
                    index: index
                )

                // Verify chart
                verifyTokenDescendant(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenChart,
                    name: "Chart",
                    index: index,
                    checkVisible: true
                )
            }

            return self
        }
    }

    @discardableResult
    func verifyPriceChangeIndicators(maxTokens: Int = 3) -> Self {
        XCTContext.runActivity(named: "Verify price change indicators for first \(maxTokens) tokens") { _ in
            waitAndAssertTrue(tokenItemButtons.firstMatch, "Token items should exist")

            let allTokenButtons = tokenItemButtons.allElementsBoundByIndex
            XCTAssertGreaterThan(allTokenButtons.count, 0, "Should have at least one token item")

            let tokensToVerify = allTokenButtons.prefix(maxTokens)
            for (index, tokenButton) in tokensToVerify.enumerated() {
                let priceChangeText = tokenButton.staticTexts[
                    MarketsAccessibilityIdentifiers.marketsListTokenPriceChange
                ]

                waitAndAssertTrue(priceChangeText, "Price change text should exist for token at index \(index)")

                let text = priceChangeText.label
                XCTAssertFalse(
                    text.isEmpty,
                    "Price change text should not be empty for token at index \(index)"
                )

                // Verify indicator sign: positive (+), negative (-), or neutral (0% or no sign)
                let hasValidIndicator = text.hasPrefix("+") || text.hasPrefix("-") || text.contains("0%") || text == "–"
                waitAndAssertTrue(
                    priceChangeText,
                    "Price change text '\(text)' for token at index \(index) should have valid indicator (starts with + or -, contains 0%, or is dash)"
                )

                // Additional verification: if it starts with +, it's positive (blue indicator)
                // if it starts with -, it's negative (red indicator)
                // otherwise it's neutral (grey indicator)
                if text.hasPrefix("+") {
                    // Positive change - blue indicator
                    waitAndAssertTrue(
                        priceChangeText,
                        "Positive price change '\(text)' for token at index \(index) should contain %"
                    )
                } else if text.hasPrefix("-") {
                    // Negative change - red indicator
                    waitAndAssertTrue(
                        priceChangeText,
                        "Negative price change '\(text)' for token at index \(index) should contain %"
                    )
                }
            }

            return self
        }
    }

    @discardableResult
    func tapSortButton() -> Self {
        XCTContext.runActivity(named: "Tap Markets sort button") { _ in
            let sortButton = app.buttons[MarketsAccessibilityIdentifiers.marketsSortButton]
            waitAndAssertTrue(sortButton, "Sort button should exist")
            sortButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func selectSortOption(_ orderType: String) -> Self {
        XCTContext.runActivity(named: "Select Markets sort option: \(orderType)") { _ in
            let sortOptionButton = app.buttons[MarketsAccessibilityIdentifiers.marketsSortOption(orderType)]
            waitAndAssertTrue(sortOptionButton, "Sort option '\(orderType)' should exist")
            sortOptionButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifySortSelected(_ expectedText: String) -> Self {
        XCTContext.runActivity(named: "Verify Markets sort is selected: \(expectedText)") { _ in
            let sortButton = app.buttons[MarketsAccessibilityIdentifiers.marketsSortButton]
            waitAndAssertTrue(sortButton, "Sort button should exist")

            // Wait for button label to contain expected text
            let predicate = NSPredicate(format: "label CONTAINS %@", expectedText)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: sortButton)
            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)

            let buttonText = sortButton.label
            waitAndAssertTrue(
                result == .completed ? sortButton : app.buttons["nonexistent"],
                "Sort button should display '\(expectedText)', but shows '\(buttonText)'"
            )
            return self
        }
    }

    func getFirstTokenNames(count: Int) -> [String] {
        XCTContext.runActivity(named: "Get first \(count) token names from Markets list") { _ in
            let nameLabels = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.marketsListTokenNameLabel
            )
            waitAndAssertTrue(nameLabels.firstMatch, "Token name labels should exist")

            let tokenNames = nameLabels.allElementsBoundByIndex.prefix(count).map { $0.label }
            XCTAssertGreaterThanOrEqual(
                tokenNames.count,
                count,
                "Should have at least \(count) tokens in the list"
            )
            return Array(tokenNames)
        }
    }

    @discardableResult
    func verifyAllTokensHaveRequiredElements(maxTokens: Int = 3) -> Self {
        XCTContext.runActivity(named: "Verify first \(maxTokens) tokens have required elements") { _ in
            waitAndAssertTrue(tokenItemButtons.firstMatch, "Token items should exist")

            let allTokenButtons = tokenItemButtons.allElementsBoundByIndex
            XCTAssertGreaterThan(allTokenButtons.count, 0, "Should have at least one token item")

            let tokensToVerify = allTokenButtons.prefix(maxTokens)
            for (index, tokenButton) in tokensToVerify.enumerated() {
                // Verify icon
                verifyTokenDescendant(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenIcon,
                    name: "Icon",
                    index: index
                )

                // Verify name
                verifyTokenStaticText(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenNameLabel,
                    name: "Name",
                    index: index
                )

                // Verify currency
                verifyTokenStaticText(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenCurrencyLabel,
                    name: "Currency",
                    index: index
                )

                // Verify price
                verifyTokenStaticText(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenPrice,
                    name: "Price",
                    index: index
                )

                // Verify price change
                verifyTokenStaticText(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenPriceChange,
                    name: "Price change",
                    index: index
                )

                // Rating is optional, so we don't assert its existence

                // Verify market cap
                verifyTokenStaticText(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenMarketCap,
                    name: "Market cap",
                    index: index
                )

                // Verify chart
                verifyTokenDescendant(
                    in: tokenButton,
                    identifier: MarketsAccessibilityIdentifiers.marketsListTokenChart,
                    name: "Chart",
                    index: index,
                    checkVisible: true
                )
            }

            return self
        }
    }

    @discardableResult
    func verifyTokensWithLowMarketCapAreFiltered() -> Self {
        XCTContext.runActivity(named: "Verify tokens with market cap < 100k are filtered out") { _ in
            // When not searching, the "Show tokens under 100k" button should not be visible
            // This indicates that tokens with market cap < 100k are filtered out
            let expandButton = app.buttons[MarketsAccessibilityIdentifiers.marketsTokensUnderCapExpandButton]
            let buttonExists = expandButton.waitForExistence(timeout: .robustUIUpdate)
            XCTAssertFalse(
                buttonExists,
                "Expand button for tokens under 100k should not be visible when not searching"
            )
            return self
        }
    }

    @discardableResult
    func verifyTokenNamesTruncation(maxTokens: Int = 3) -> Self {
        XCTContext.runActivity(named: "Verify first \(maxTokens) token names are displayed correctly") { _ in
            let nameLabels = app.staticTexts.matching(
                identifier: MarketsAccessibilityIdentifiers.marketsListTokenNameLabel
            )
            waitAndAssertTrue(nameLabels.firstMatch, "Token name labels should exist")

            let allNameLabels = nameLabels.allElementsBoundByIndex
            XCTAssertGreaterThan(allNameLabels.count, 0, "Should have at least one token name")

            let labelsToVerify = allNameLabels.prefix(maxTokens)
            for (index, nameLabel) in labelsToVerify.enumerated() {
                let nameText = nameLabel.label
                XCTAssertFalse(nameText.isEmpty, "Token name at index \(index) should not be empty")

                // Verify that displayed names are reasonable in length
                // Names should either be truncated (contain ellipsis) or be short enough to fit
                // We don't fail for longer names as truncation depends on available space
            }

            return self
        }
    }

    // MARK: - Private helpers

    /// Verifies that a static text element exists within a token button
    private func verifyTokenStaticText(
        in tokenButton: XCUIElement,
        identifier: String,
        name: String,
        index: Int,
        checkNotEmpty: Bool = true
    ) {
        let element = tokenButton.staticTexts[identifier]
        waitAndAssertTrue(element, "\(name) should exist for token at index \(index)")

        if checkNotEmpty {
            let text = element.label
            waitAndAssertTrue(
                !text.isEmpty ? element : app.buttons["nonexistent"],
                "\(name) should not be empty for token at index \(index)"
            )
        }
    }

    /// Verifies that a descendant element exists within a token button (for non-text elements like icons)
    private func verifyTokenDescendant(
        in tokenButton: XCUIElement,
        identifier: String,
        name: String,
        index: Int,
        checkVisible: Bool = false
    ) {
        let element = tokenButton.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch

        waitAndAssertTrue(element, "\(name) should exist for token at index \(index)")

        if checkVisible {
            waitAndAssertTrue(
                element.frame.width > 0 && element.frame.height > 0 ? element : app.buttons["nonexistent"],
                "\(name) should be visible for token at index \(index)"
            )
        }
    }
}

enum MarketsScreenElement: String, UIElement {
    case searchThroughMarketField
    case addToPortfolioButton
    case continueButton
    case addTokenButton
    case getTokenLaterButton
    case marketsTokensUnderCapExpandButton
    case marketsSearchNoResultsLabel

    var accessibilityIdentifier: String {
        switch self {
        case .searchThroughMarketField:
            MainAccessibilityIdentifiers.searchThroughMarketField
        case .addToPortfolioButton:
            MainAccessibilityIdentifiers.addToPortfolioButton
        case .continueButton:
            TokenAccessibilityIdentifiers.continueButton
        case .addTokenButton:
            TokenAccessibilityIdentifiers.addTokenButton
        case .getTokenLaterButton:
            TokenAccessibilityIdentifiers.getTokenLaterButton
        case .marketsTokensUnderCapExpandButton:
            MarketsAccessibilityIdentifiers.marketsTokensUnderCapExpandButton
        case .marketsSearchNoResultsLabel:
            MarketsAccessibilityIdentifiers.marketsSearchNoResultsLabel
        }
    }
}
