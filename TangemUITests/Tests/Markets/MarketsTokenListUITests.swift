//
//  MarketsTokenListUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest
import TangemAccessibilityIdentifiers

final class MarketsTokenListUITests: BaseTestCase {
    func testMarketsIntervalsChangeUpdatesData() {
        setAllureId(50)

        launchApp()

        let markets = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .verifyIntervalSelected("24h")
            .selectInterval("1w")
            .verifyIntervalSelected("1w")

        let priceChange7d = markets.firstPriceChangeText()

        markets
            .selectInterval("1m")
            .verifyIntervalSelected("1m")
            .waitForPriceChangeData()

        let priceChange30d = markets.firstPriceChangeText()
        XCTAssertNotEqual(priceChange30d, priceChange7d, "Price change should update after switching to 30d interval")
    }

    func testMarketsPriceChangeDisplay() {
        setAllureId(55)

        launchApp()

        let markets = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .verifyTokensHavePriceChangeAndCharts()

        let initialPriceChange = markets.firstPriceChangeText()

        markets
            .selectInterval("1w")
            .verifyIntervalSelected("1w")
            .waitForPriceChangeData()

        let updatedPriceChange = markets.firstPriceChangeText()
        XCTAssertNotEqual(
            updatedPriceChange,
            initialPriceChange,
            "Price change percentage should update after changing interval"
        )
    }

    func testMarketsSortOrderChange() {
        setAllureId(49)

        launchApp()

        let markets = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .verifySortSelected(SortOption.rating.displayName)

        let initialTokenOrder = markets.getFirstTokenNames(count: 5)
        XCTAssertGreaterThanOrEqual(initialTokenOrder.count, 3, "Should have at least 3 tokens to compare order")

        // Test all sort options except rating (which is the default)
        let sortOptionsToTest: [SortOption] = [.trending, .buyers, .gainers, .losers, .staking]

        for sortOption in sortOptionsToTest {
            markets.tapSortButton()

            markets.selectSortOption(sortOption.rawValue)

            let sortButton = app.buttons[MarketsAccessibilityIdentifiers.marketsSortButton]
            XCTAssertTrue(
                sortButton.waitForExistence(timeout: .robustUIUpdate),
                "Sort button should exist after selecting sort option"
            )

            markets.verifySortSelected(sortOption.displayName)

            markets.waitForPriceChangeData()
            let newTokenOrder = markets.getFirstTokenNames(count: 5)
            XCTAssertNotEqual(
                newTokenOrder,
                initialTokenOrder,
                "Token order should change after selecting '\(sortOption.displayName)' sort option"
            )
        }
    }

    func testMarketsSheetStatePersistenceWithinSessionAndResetAfterRestart() {
        setAllureId(52)

        launchApp()

        let markets = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()

        let sortButton = app.buttons[MarketsAccessibilityIdentifiers.marketsSortButton]
        XCTAssertTrue(
            sortButton.waitForExistence(timeout: .robustUIUpdate),
            "Markets sheet should be open"
        )

        markets
            .verifyIntervalSelected("24h")
            .selectInterval("1w")
            .verifyIntervalSelected("1w")
            .verifySortSelected(SortOption.rating.displayName)
            .tapSortButton()
            .selectSortOption(SortOption.trending.rawValue)
            .verifySortSelected(SortOption.trending.displayName)

        let mainScreen = markets.closeMarketsSheetWithSwipe()

        mainScreen
            .openDetails()
            .goBackToMain()

        let marketsAfterNavigation = mainScreen.openMarketsSheetWithSwipe()

        marketsAfterNavigation
            .verifyIntervalSelected("1w")
            .verifySortSelected(SortOption.trending.displayName)

        app.terminate()
        launchApp()
        let marketsAfterRestart = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()

        marketsAfterRestart
            .verifyIntervalSelected("24h")
            .verifySortSelected(SortOption.rating.displayName)
    }

    func testMarketsTokenListDisplay() {
        setAllureId(53)

        launchApp()

        let markets = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()

        let sortButton = app.buttons[MarketsAccessibilityIdentifiers.marketsSortButton]
        XCTAssertTrue(
            sortButton.waitForExistence(timeout: .robustUIUpdate),
            "Markets sheet should be open"
        )

        markets
            .verifyAllTokensHaveRequiredElements()
            .verifyTokensWithLowMarketCapAreFiltered()
            .verifyTokenNamesTruncation()
    }

    enum SortOption: String, CaseIterable {
        case rating
        case trending
        case buyers
        case gainers
        case losers
        case staking

        public var displayName: String {
            switch self {
            case .rating: return "Capitalization"
            case .trending: return "Trending"
            case .buyers: return "Experienced buyers"
            case .gainers: return "Top Gainers"
            case .losers: return "Top Losers"
            case .staking: return "Staking"
            }
        }

        public var accessibilityIdentifier: String {
            MarketsAccessibilityIdentifiers.marketsSortOption(rawValue)
        }
    }
}
