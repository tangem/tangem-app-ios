//
//  SwapStoriesUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapStoriesUITests: BaseTestCase {
    private let ethereumTokenName = "Ethereum"

    func testSwapStories_BadgeIndicatorOnTokenDetailsScreen() {
        setAllureId(5454)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        let tokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken(ethereumTokenName)
            .waitForActionButtons()
            .assertSwapButtonHasBadge()

        tokenScreen
            .tapSwapButton()
            .closeStories()
            .validateSwapScreenDisplayed()
            .tapCloseButton()
            .assertSwapButtonHasNoBadge()
    }

    func testSwapStories_BadgeIndicatorOnMainScreen() {
        setAllureId(5453)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .waitActionButtonsEnabled()
            .assertSwapButtonHasBadge()

        mainScreen
            .tapMainSwap()
            .closeStoriesAndReturnToMain()
            .waitSwapTokenSelectorDisplayed()
            .tapCloseButton()
            .assertSwapButtonHasNoBadge()
    }

    func testSwapStories_BadgeIndicatorOnTokenScreenInMarkets() throws {
        setAllureId(5455)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        let marketsTokenDetailsScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .openMarketsSheetWithSwipe()
            .tapSeeAll()
            .openTokenDetails(ethereumTokenName)
            .assertSwapButtonHasBadge()

        marketsTokenDetailsScreen
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapCloseButtonAndReturnToMarkets()
            .assertSwapButtonHasNoBadge()
    }

    func testSwapStories_StoriesDisplayOnMainScreen() {
        setAllureId(5474)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        // Step 1: Open swap from main screen → stories open
        let storiesScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .waitActionButtonsEnabled()
            .tapMainSwap()
            .assertStoriesDisplayed()

        // Step 2: Navigate stories forward and backward, verify close button on each page
        storiesScreen
            .assertCloseButtonVisible()
            .tapStoryForward()
            .assertCloseButtonVisible()
            .tapStoryForward()
            .assertCloseButtonVisible()
            .tapStoryBackward()
            .assertCloseButtonVisible()
            .tapStoryForward()

        // Step 3: Close stories → swap token selector opens
        storiesScreen
            .closeStoriesAndReturnToMain()
            .waitSwapTokenSelectorDisplayed()
            .tapCloseButton()

        // Step 4: Open swap again → stories should not show
        MainScreen(app)
            .waitActionButtonsEnabled()
            .tapMainSwap()
            .assertStoriesNotDisplayed()

        SwapTokenSelectorScreen(app)
            .waitSwapTokenSelectorDisplayed()
            .tapCloseButton()
    }

    func testSwapStories_StoriesDisplayOnTokenDetailsScreen() {
        setAllureId(5475)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        // Step 1: Navigate to token details and open swap → stories open
        let storiesScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken(ethereumTokenName)
            .waitForActionButtons()
            .tapSwapButton()
            .assertStoriesDisplayed()

        // Step 2: Navigate stories forward and backward, verify close button on each page
        storiesScreen
            .assertCloseButtonVisible()
            .tapStoryForward()
            .assertCloseButtonVisible()
            .tapStoryForward()
            .assertCloseButtonVisible()
            .tapStoryBackward()
            .assertCloseButtonVisible()
            .tapStoryForward()

        // Step 3: Close stories → swap screen opens
        storiesScreen
            .closeStories()
            .validateSwapScreenDisplayed()
            .tapCloseButton()

        // Step 4: Open swap again → stories should not show
        TokenScreen(app)
            .waitForActionButtons()
            .tapSwapButton()
            .assertStoriesNotDisplayed()

        SwapScreen(app)
            .validateSwapScreenDisplayed()
            .tapCloseButton()
    }

    func testSwapStories_StoriesDisplayInMarkets() throws {
        setAllureId(5476)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        // Step 1: Navigate to markets token and open swap → stories open
        let storiesScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .openMarketsSheetWithSwipe()
            .tapSeeAll()
            .openTokenDetails(ethereumTokenName)
            .tapSwapButton()
            .assertStoriesDisplayed()

        // Step 2: Navigate stories forward and backward, verify close button on each page
        storiesScreen
            .assertCloseButtonVisible()
            .tapStoryForward()
            .assertCloseButtonVisible()
            .tapStoryForward()
            .assertCloseButtonVisible()
            .tapStoryBackward()
            .assertCloseButtonVisible()
            .tapStoryForward()

        // Step 3: Close stories → swap screen opens
        storiesScreen
            .closeStories()
            .validateSwapScreenDisplayed()
            .tapCloseButtonAndReturnToMarkets()

        // Step 4: Open swap again → stories should not show
        MarketsTokenDetailsScreen(app)
            .tapSwapButton()
            .assertStoriesNotDisplayed()

        SwapScreen(app)
            .validateSwapScreenDisplayed()
            .tapCloseButtonAndReturnToMarkets()
    }

    func testSwapStories_StoriesDisplayViaContextMenu() {
        setAllureId(5477)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true
        )

        // Step 1: Open swap from main screen context menu → stories open
        let storiesScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .longPressToken(ethereumTokenName)
            .waitForActionButtons()
            .tapSwap()
            .assertStoriesDisplayed()

        // Step 2: Navigate stories forward and backward, verify close button on each page
        storiesScreen
            .assertCloseButtonVisible()
            .tapStoryForward()
            .assertCloseButtonVisible()
            .tapStoryForward()
            .assertCloseButtonVisible()
            .tapStoryBackward()
            .assertCloseButtonVisible()
            .tapStoryForward()

        // Step 3: Close stories → swap screen opens
        storiesScreen
            .closeStories()
            .validateSwapScreenDisplayed()
            .tapCloseButton()

        // Step 4: Open swap via context menu again → stories should not show
        MainScreen(app)
            .waitActionButtonsEnabled()
            .longPressToken(ethereumTokenName)
            .waitForActionButtons()
            .tapSwap()
            .assertStoriesNotDisplayed()

        SwapScreen(app)
            .validateSwapScreenDisplayed()
            .tapCloseButton()
    }

    func testSwapStories_UnavailableStoriesOnMarketsTokenDetailsScreen() throws {
        setAllureId(5470)

        let storiesErrorScenario = ScenarioConfig(name: "stories_first_time_swap", initialState: "Error")

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [storiesErrorScenario]
        )

        let marketsTokenDetailsScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .openMarketsSheetWithSwipe()
            .tapSeeAll()
            .openTokenDetails(ethereumTokenName)
            .assertSwapButtonHasNoBadge()

        marketsTokenDetailsScreen
            .tapSwapButton()
            .assertStoriesNotDisplayed()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapCloseButtonAndReturnToMarkets()

        wireMockClient.resetScenarioSync("stories_first_time_swap")
        app.terminate()
        launchApp(tangemApiType: .mock, clearStorage: false)

        let marketsTokenDetailsScreenAfterRestart = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .openMarketsSheetWithSwipe()
            .tapSeeAll()
            .openTokenDetails(ethereumTokenName)
            .assertSwapButtonHasBadge()

        marketsTokenDetailsScreenAfterRestart
            .tapSwapButton()
            .assertStoriesDisplayed()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapCloseButtonAndReturnToMarkets()
    }

    func testSwapStories_UnavailableStoriesOnMainScreen() {
        setAllureId(5469)

        let storiesErrorScenario = ScenarioConfig(name: "stories_first_time_swap", initialState: "Error")

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [storiesErrorScenario]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .waitActionButtonsEnabled()
            .assertSwapButtonHasNoBadge()

        mainScreen
            .tapMainSwap()
            .assertStoriesNotDisplayed()

        SwapTokenSelectorScreen(app)
            .waitSwapTokenSelectorDisplayed()
            .tapCloseButton()
            .assertSwapButtonHasNoBadge()

        wireMockClient.resetScenarioSync("stories_first_time_swap")
        app.terminate()
        launchApp(tangemApiType: .mock, clearStorage: false)

        let mainScreenAfterRestart = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .waitActionButtonsEnabled()
            .assertSwapButtonHasBadge()

        mainScreenAfterRestart
            .tapMainSwap()
            .assertStoriesDisplayed()
            .closeStoriesAndReturnToMain()
            .waitSwapTokenSelectorDisplayed()
            .tapCloseButton()
    }

    func testSwapStories_UnavailableStoriesOnTokenDetailsScreen() {
        setAllureId(5471)

        let storiesErrorScenario = ScenarioConfig(name: "stories_first_time_swap", initialState: "Error")

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [storiesErrorScenario]
        )

        let tokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken(ethereumTokenName)
            .waitForActionButtons()
            .assertSwapButtonHasNoBadge()

        tokenScreen
            .tapSwapButton()
            .assertStoriesNotDisplayed()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapCloseButton()
            .assertSwapButtonHasNoBadge()

        wireMockClient.resetScenarioSync("stories_first_time_swap")
        app.terminate()
        launchApp(tangemApiType: .mock, clearStorage: false)

        let tokenScreenAfterRestart = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapToken(ethereumTokenName)
            .waitForActionButtons()
            .assertSwapButtonHasBadge()

        tokenScreenAfterRestart
            .tapSwapButton()
            .assertStoriesDisplayed()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapCloseButton()
    }
}
