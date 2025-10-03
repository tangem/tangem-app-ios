//
//  TotalBalanceSmokeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class TotalBalanceSmokeUITests: BaseTestCase {
    func testLongPressWalletHeader_NoRenameAndDeleteButtons() {
        setAllureId(3965)
        launchApp(tangemApiType: .mock)

        let mainScreen = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressWalletHeader()

        mainScreen.waitForNoRenameButton()
        mainScreen.waitForDeleteButtonExists()
    }

    func testTotalBalanceDisplayed_BeforeAndAfterPullToRefresh() {
        setAllureId(150)
        launchApp(tangemApiType: .mock)

        let mainScreen = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceDisplayed()

        pullToRefresh()

        mainScreen.waitForTotalBalanceDisplayed()
    }

    func testNavigateToAppSettingsAndTapCurrencyButton() {
        setAllureId(3996)
        let currencyScenario = ScenarioConfig(
            name: "currencies_api",
            initialState: "AppSettings"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [currencyScenario]
        )

        let appSettingsScreen = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openAppSettings()
            .validateScreenElements()
            .tapCurrencyButton()
            .validateScreenElements()
            .selectCurrency("RUB")

        let mainScreen = appSettingsScreen
            .goBackToDetails()
            .goBackToMain()
            .waitForTotalBalanceContainsCurrency("₽")

        let updatedAppSettingsScreen = mainScreen
            .openDetails()
            .openAppSettings()
            .tapCurrencyButton()
            .selectCurrency("USD")

        updatedAppSettingsScreen
            .goBackToDetails()
            .goBackToMain()
            .waitForTotalBalanceContainsCurrency("$")
    }

    func testTotalBalancePersistsAfterAppMinimizeAndMaximize() {
        setAllureId(4000)
        launchApp(tangemApiType: .mock)

        let mainScreen = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceDisplayed()

        let balanceBefore = mainScreen.getTotalBalanceValue()

        minimizeApp()
        maximizeApp()

        let balanceAfter = mainScreen.getTotalBalanceValue()

        XCTAssertEqual(balanceBefore, balanceAfter, "Total balance should remain the same after app minimize/maximize")
    }

    func testTotalBalancePersistsAfterNavigationToDetailsAndTokenScreen() {
        setAllureId(4001)
        launchApp(tangemApiType: .mock)

        let mainScreen = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceDisplayed()

        let initialBalance = mainScreen.getTotalBalanceValue()

        mainScreen
            .openDetails()
            .goBackToMain()

        let balanceAfterDetails = mainScreen.getTotalBalanceValue()
        XCTAssertEqual(initialBalance, balanceAfterDetails, "Total balance should remain the same after navigating to details and back")

        mainScreen
            .tapToken("Polygon")
            .goBackToMain()

        let balanceAfterToken = mainScreen.getTotalBalanceValue()
        XCTAssertEqual(initialBalance, balanceAfterToken, "Total balance should remain the same after navigating to Polygon token and back")
    }

    func testShowedDashInsteadOfBalance() {
        setAllureId(3995)

        let token = "Myria"
        let quotesErrorScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "CustomTokenAdded"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [quotesErrorScenario]
        )

        let tokenBalance = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .getTokenBalance(tokenName: token)

        XCTAssert(tokenBalance == "–", "Expecting dash symbol instead of balance")
    }

    func testQuotesError_TotalBalanceDisplayedAsDash() {
        setAllureId(3994)

        let quotesErrorScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Error"
        )

        let coinsListErrorScenario = ScenarioConfig(
            name: "coins_list_api",
            initialState: "Error"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [quotesErrorScenario, coinsListErrorScenario]
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceDisplayedAsDash()
    }

    func testQuotesSlow_TotalBalanceDisplayedAsDash() {
        setAllureId(151)

        let quotesDelayScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "SlowResponse"
        )

        let coinsListDelayScenario = ScenarioConfig(
            name: "coins_list_api",
            initialState: "SlowResponse"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [coinsListDelayScenario, quotesDelayScenario]
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmer()
            .waitForTotalBalanceDisplayed()
    }
}
