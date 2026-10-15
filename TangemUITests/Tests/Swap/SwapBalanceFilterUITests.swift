//
//  SwapBalanceFilterUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapBalanceFilterUITests: BaseTestCase {
    func testHideZeroBalanceFilter_EnabledByDefault() {
        setAllureId(10862)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.polygonCoinBalance, initialState: Constants.Scenario.zeroBalanceState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapFromTokenSelector()
            .waitBalanceFilterChipLabel(contains: Constants.hideZeroBalanceLabel)
            .waitForTokenDisplayed(Constants.Token.polInSelector)
            .waitForTokenNotDisplayed(Constants.Token.polygon)
    }

    func testHideZeroBalanceFilter_AllTokensZeroBalance() {
        setAllureId(10863)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: Constants.Scenario.userTokensApi, initialState: Constants.Scenario.totalBalanceTokensZeroState),
                ScenarioConfig(name: Constants.Scenario.rippleAccountInfo, initialState: Constants.Scenario.emptyState),
                ScenarioConfig(name: Constants.Scenario.ethCallApi, initialState: Constants.Scenario.emptyState),
                ScenarioConfig(name: Constants.Scenario.ethNetworkBalance, initialState: Constants.Scenario.emptyState),
            ]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapFromTokenSelector()
            .waitForFilteredOutEmptyMessageDisplayed()
            .tapSeeAllButton()
            .waitBalanceFilterChipLabel(contains: Constants.allFilterLabel)
            .waitForTokenDisplayed(Constants.Token.ethereum)
    }

    func testHideZeroBalanceFilter_Search() {
        setAllureId(10869)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.polygonCoinBalance, initialState: Constants.Scenario.zeroBalanceState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapFromTokenSelector()
            .typeSearchText(Constants.Token.polInSelector)
            .waitForTokenDisplayed(Constants.Token.polInSelector)
            .clearSearchText()
            .typeSearchText(Constants.Token.polygon)
            .waitForTokenNotDisplayed(Constants.Token.polygon)
    }

    func testEnableAllTokensFilter() {
        setAllureId(10866)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.polygonCoinBalance, initialState: Constants.Scenario.zeroBalanceState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapFromTokenSelector()
            .waitForTokenDisplayed(Constants.Token.polInSelector)
            .waitForTokenNotDisplayed(Constants.Token.polygon)
            .selectBalanceFilter(.all)
            .waitForTokenDisplayed(Constants.Token.polygon)
    }

    func testAllTokensFilter_Search() {
        setAllureId(10870)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.polygonCoinBalance, initialState: Constants.Scenario.zeroBalanceState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapFromTokenSelector()
            .selectBalanceFilter(.all)
            .waitForTokenDisplayed(Constants.Token.polygon)
            .typeSearchText(Constants.Token.polygon)
            .waitForTokenDisplayed(Constants.Token.polygon)
            .clearSearchText()
            .typeSearchText(Constants.Token.polInSelector)
            .waitForTokenDisplayed(Constants.Token.polInSelector)
    }
}

private extension SwapBalanceFilterUITests {
    enum Constants {
        static let hideZeroBalanceLabel = "Hide 0 balance"
        static let allFilterLabel = "All"

        enum Token {
            static let polInSelector = "POL (ex-MATIC)"
            static let polygon = "Polygon"
            static let ethereum = "Ethereum"
        }

        enum Scenario {
            static let polygonCoinBalance = "polygon_coin_balance"
            static let zeroBalanceState = "ZeroBalance"

            static let userTokensApi = "user_tokens_api"
            static let totalBalanceTokensZeroState = "TOTAL_BALANCE_TOKENS_ZERO"

            static let rippleAccountInfo = "ripple_account_info"
            static let ethCallApi = "eth_call_api"
            static let ethNetworkBalance = "eth_network_balance"
            static let emptyState = "Empty"
        }
    }
}
