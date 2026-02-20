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

        try skipDueToBug("[REDACTED_INFO]", description: "Auto-expand quick actions doesn't work for token in Markets portfolio")

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
            .expandTokenActionButtons(tokenName: ethereumTokenName)
            .assertSwapButtonHasBadge()

        marketsTokenDetailsScreen
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapCloseButtonAndReturnToMarkets()
            .assertSwapButtonHasNoBadge()
    }

    func testSwapStories_UnavailableStoriesOnMarketsTokenDetailsScreen() throws {
        setAllureId(5470)

        try skipDueToBug("[REDACTED_INFO]", description: "Auto-expand quick actions doesn't work for token in Markets portfolio")

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
            .expandTokenActionButtons(tokenName: ethereumTokenName)
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
            .expandTokenActionButtons(tokenName: ethereumTokenName)
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
