//
//  SwapWarningsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapWarningsUITests: BaseTestCase {
    func testInsufficientFundsWarning() {
        setAllureId(580)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Polygon")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Ethereum")

        swapScreen
            .enterFromAmount("1000")
            .waitForInsufficientFundsError()
            .waitForConfirmButtonDisabled()
    }

    func testUnableToCoverBlockchainFeeSolana() {
        setAllureId(8502)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "SolanaUSDC"),
                ScenarioConfig(name: "quotes_api", initialState: "SolanaUSDC"),
                ScenarioConfig(name: "solana_balance", initialState: "Empty"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("USDC")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Solana")

        swapScreen
            .enterFromAmount("1000")
            .waitForNotificationShown()
            .waitForNotificationIcon()
            .waitForConfirmButtonDisabled()
    }

    func testHighPriceImpactCEX() {
        setAllureId(8503)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "SolanaUSDC"),
                ScenarioConfig(name: "quotes_api", initialState: "SolanaUSDC"),
                ScenarioConfig(name: "exchange_quote_solana", initialState: "HighPriceImpact"),
                ScenarioConfig(name: "solana_balance", initialState: "Empty"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("USDC")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Solana")

        swapScreen
            .enterFromAmount("100")
            .waitForPriceChangeWarningDisplayed()

        swapScreen
            .tapPriceChangeInfoButton()
            .waitForAlertAndDismiss()
    }

    // MARK: - Solana Rent Fee Warning Tests

    func testRentFeeWarningDisplayed_WhenRemainingBalanceLessThanRent() {
        setAllureId(2830)

        let swapScreen = prepareSwapSolanaFlow()

        swapScreen
            .enterFromAmount("0.0016941")
            .waitForNotificationShown(title: "Invalid amount")
            .waitForNotificationIcon()
            .waitForConfirmButtonDisabled()
    }

    func testRentFeeWarningNotDisplayed_WhenRemainingBalanceEqualsZero() {
        setAllureId(2831)

        let swapScreen = prepareSwapSolanaFlow()

        swapScreen
            .enterFromAmount("0.00168933")
            .waitForNotificationNotShown()
            .waitForConfirmButtonEnabled()
    }

    func testRentFeeWarningNotDisplayed_WhenRemainingBalanceEqualsRent() {
        setAllureId(2832)

        let swapScreen = prepareSwapSolanaFlow()

        swapScreen
            .enterFromAmount("0.001689338")
            .waitForNotificationNotShown()
            .waitForConfirmButtonEnabled()
    }

    func testRentFeeWarningNotDisplayed_WhenRemainingBalanceGreaterThanRent() {
        setAllureId(2833)

        let swapScreen = prepareSwapSolanaFlow()

        swapScreen
            .enterFromAmount("0.0000941")
            .waitForNotificationNotShown()
            .waitForConfirmButtonEnabled()
    }

    // MARK: - High Price Impact Tests

    func testHighPriceImpactDEX() {
        setAllureId(8504)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "polygon_pos_to_pairs", initialState: "DexProvider"),
                ScenarioConfig(name: "polygon_pos_from_pairs", initialState: "DexProvider"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Polygon")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Ethereum")

        swapScreen
            .enterFromAmount("1000")
            .waitForPriceChangeWarningDisplayed()

        swapScreen
            .tapPriceChangeInfoButton()
            .waitForAlertAndDismiss()
    }

    func testHighPriceImpactFromMainScreen() {
        setAllureId(8964)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "quotes_api", initialState: "MediumPriceImpactMain"),
                // The Markets widget refreshes prices via /v1/coins/list into the same quotes cache, clobbering quotesScenario's ETH price without this.
                ScenarioConfig(name: "coins_list_api", initialState: "MediumPriceImpactMain"),
            ]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()

        let swapScreen = mainScreen
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseSourceToken("Polygon")
            .chooseReceiveToken("Ethereum")

        swapScreen
            .enterFromAmount("300")

        swapScreen
            .waitForNotificationShown(title: "High price impact")

        swapScreen
            .tapPriceChangeInfoButton()
            .waitForAlertAndDismiss()
    }

    func testTradeTooLargeFromMainScreen() {
        setAllureId(8965)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "quotes_api", initialState: "HighPriceImpact"),
                // See testHighPriceImpactFromMainScreen for why this is needed alongside quotesScenario.
                ScenarioConfig(name: "coins_list_api", initialState: "HighPriceImpact"),
            ]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmerToComplete()

        let swapScreen = mainScreen
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseSourceToken("Polygon")
            .chooseReceiveToken("Ethereum")

        swapScreen
            .enterFromAmount("300")
            .waitForNotificationShown(title: "Trade too large")

        swapScreen
            .tapPriceChangeInfoButton()
            .waitForAlertAndDismiss()
    }

    // MARK: - Private

    private func prepareSwapSolanaFlow() -> SwapScreen {
        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "SolanaUSDC"),
                ScenarioConfig(name: "quotes_api", initialState: "SolanaUSDC"),
            ]
        )

        return CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Solana")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("USDC")
    }
}
