//
//  SwapDeeplinksUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapDeeplinksUITests: BaseTestCase {
    private let fromTokenSymbol = "POL"
    private let toTokenSymbol = "ETH"
    private let providerName = "1Inch"

    private let safariHelper = SafariHelper()

    private let standardScenarios = [
        ScenarioConfig(name: "user_tokens_api", initialState: "HotWalletSvS"),
        ScenarioConfig(name: "quotes_api", initialState: "PolygonUSDC"),
        ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
        ScenarioConfig(name: "ethereum_from_pairs", initialState: "DexProvider"),
    ]

    func testFullValidParamsOpensSwapPrefilled() {
        setAllureId(10913)
        let amount = "0.0008"
        let userWalletId = "916A3887E37D720A7D8FBC8CD08EF4B1793E40B70C30D81259BB6E858B9FBA24"
        let userAccountId = "DD7370CB6A0CDAFEFAB175676F0C854D2AA9570B1F96536969EAF2E6B329C76C"
        let query = "from_token_id=polygon-ecosystem-token&from_network_id=ethereum" +
            "&to_token_id=ethereum&to_network_id=ethereum" +
            "&from_amount=\(amount)&provider_id=1inch" +
            "&user_wallet_id=\(userWalletId)" +
            "&from_user_account_id=\(userAccountId)&to_user_account_id=\(userAccountId)"

        launchApp(tangemApiType: .mock, expressApiType: .mock, clearStorage: true, scenarios: standardScenarios)
        importHotWallet()

        openSwapDeeplink(query)
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: toTokenSymbol)
            .waitForFromAmountValue(amount)
            .verifyProviderName(contains: providerName)
    }

    func testPairWithoutAmountOpensSwapWithEmptyAmount() {
        setAllureId(10914)
        let emptyAmountPlaceholder = "0"
        let query = "from_token_id=polygon-ecosystem-token&from_network_id=ethereum" +
            "&to_token_id=ethereum&to_network_id=ethereum"

        launchApp(tangemApiType: .mock, expressApiType: .mock, clearStorage: true, scenarios: standardScenarios)
        importHotWallet()

        openSwapDeeplink(query)
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: toTokenSymbol)
            .waitForFromAmountValue(emptyAmountPlaceholder)
    }

    func testAmountGreaterThanBalanceShowsInsufficientFunds() {
        setAllureId(10917)
        let amount = "999999"
        let formattedAmount = "999,999"
        let query = "from_token_id=polygon-ecosystem-token&from_network_id=ethereum" +
            "&to_token_id=ethereum&to_network_id=ethereum" +
            "&from_amount=\(amount)"

        launchApp(tangemApiType: .mock, expressApiType: .mock, clearStorage: true, scenarios: standardScenarios)
        importHotWallet()

        openSwapDeeplink(query)
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: toTokenSymbol)
            .waitForFromAmountValue(formattedAmount)
            .waitForInsufficientFundsError()
    }

    func testInvalidUserWalletIdIsTreatedAsAbsent() {
        setAllureId(10921)
        let query = "user_wallet_id=C10EC74B93FD8195BC0A0ACF7D6C2795C056485C47DC706698F0461CCBFD9EF5"

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "HotWalletSvS"),
                ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
            ]
        )
        importHotWallet()

        openSwapDeeplink(query)
            .validateSwapScreenDisplayed()
            .waitForNotificationNotShown()
    }

    func testDeeplinkWhileAppKilledColdStartsIntoSwap() {
        setAllureId(10925)
        let amount = "0.0008"
        let query = "from_token_id=polygon-ecosystem-token&from_network_id=ethereum" +
            "&to_token_id=ethereum&to_network_id=ethereum" +
            "&from_amount=\(amount)&provider_id=1inch"

        launchApp(tangemApiType: .mock, expressApiType: .mock, clearStorage: true, scenarios: standardScenarios)
        importHotWallet()
        app.terminate()

        openSwapDeeplink(query)
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: toTokenSymbol)
            .waitForFromAmountDisplayedValue(amount)
    }

    /// [REDACTED_INFO] Deeplink for Swap: Multiple swap bottom sheets stack on top of each other when opening a deeplink repeatedly
    func skipped_testDeeplinkFromSwapScreenOpensNewSwapWithUpdatedAmount() {
        setAllureId(10928)
        let firstAmount = "0.0008"
        let secondAmount = "0.002"
        let firstQuery = "from_token_id=polygon-ecosystem-token&from_network_id=ethereum" +
            "&to_token_id=ethereum&to_network_id=ethereum" +
            "&from_amount=\(firstAmount)&provider_id=1inch"
        let secondQuery = "from_token_id=polygon-ecosystem-token&from_network_id=ethereum" +
            "&to_token_id=ethereum&to_network_id=ethereum" +
            "&from_amount=\(secondAmount)&provider_id=1inch"

        launchApp(tangemApiType: .mock, expressApiType: .mock, clearStorage: true, scenarios: standardScenarios)
        importHotWallet()

        openSwapDeeplink(firstQuery)
            .waitForFromAmountValue(firstAmount)

        openSwapDeeplink(secondQuery)
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: toTokenSymbol)
            .waitForFromAmountValue(secondAmount)
    }

    func testDeeplinkThroughClickableBannerOpensSwap() {
        setAllureId(10924)
        let tokenDetailsTitle = "Ethereum"
        let bannerText = "Swap POL for ETH"
        let amount = "0.0008"

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: standardScenarios + [
                ScenarioConfig(name: "marketing_campaigns_token_details", initialState: "TokenDetailsSwapBanner"),
            ]
        )
        importHotWallet()
            .tapToken(tokenDetailsTitle)
            .verifyMarketingBannerDisplayed(text: bannerText)
            .tapMarketingBanner()
            .closeStoriesIfNeeded()
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: toTokenSymbol)
            .waitForFromAmountValue(amount)
            .verifyProviderName(contains: providerName)
    }

    func testDeeplinkWhileOfflineShowsNetworkError() {
        setAllureId(11563)
        let amount = "0.0008"
        let query = "from_token_id=polygon-ecosystem-token&from_network_id=ethereum" +
            "&to_token_id=ethereum&to_network_id=ethereum" +
            "&from_amount=\(amount)"

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "HotWalletSvS"),
                ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
                ScenarioConfig(name: "quotes_api", initialState: "Error"),
            ]
        )
        importHotWallet()

        openSwapDeeplink(query)
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: toTokenSymbol)
            .waitForFromAmountValue(amount)
            .waitForNotificationShown()
            .waitForRetryButtonDisplayed()
    }

    func testOnlyFromWithAmountOpensSwapWithFromPrefilledAndNoAmount() {
        setAllureId(10915)
        let query = "from_token_id=ethereum&from_network_id=ethereum&from_amount=\(Constants.amount)"

        launchEthereumUsdcSwap(extraScenarios: [
            ScenarioConfig(name: Constants.Scenario.ethNetworkBalance, initialState: Constants.State.lessThanDollar),
        ])
        waitForPortfolioBalances(importHotWallet())

        openSwapDeeplink(query)
            .waitFromTokenDisplayed(tokenSymbol: Constants.Token.ethereumSymbol)
            .waitForToTokenNotSelected()
            .waitForFromAmountValue(Constants.emptyAmountPlaceholder)
    }

    func testOnlyToWithAmountOpensSwapWithMostFundedFromAndNoAmount() {
        setAllureId(10916)
        let query = "to_token_id=usd-coin&to_network_id=ethereum&from_amount=\(Constants.amount)"

        launchEthereumUsdcSwap()
        waitForPortfolioBalances(importHotWallet())

        openSwapDeeplink(query)
            .waitToTokenDisplayed(tokenSymbol: Constants.Token.usdcSymbol)
            .waitFromTokenDisplayed(tokenSymbol: Constants.Token.ethereumSymbol)
            .waitForFromAmountValue(Constants.emptyAmountPlaceholder)
    }

    func testProviderIdValidForPairPreselectsProvider() {
        setAllureId(10918)
        let query = "from_token_id=ethereum&from_network_id=ethereum" +
            "&to_token_id=usd-coin&to_network_id=ethereum" +
            "&from_amount=\(Constants.amount)&provider_id=changelly"

        launchEthereumUsdcSwap(extraScenarios: [
            ScenarioConfig(name: Constants.Scenario.exchangeQuoteEthereum, initialState: Constants.State.ethUsdcChangelly),
        ])
        waitForPortfolioBalances(importHotWallet())

        openSwapDeeplink(query)
            .waitFromTokenDisplayed(tokenSymbol: Constants.Token.ethereumSymbol)
            .waitToTokenDisplayed(tokenSymbol: Constants.Token.usdcSymbol)
            .waitForFromAmountValue(Constants.amount)
            .verifyProviderName(contains: Constants.Provider.changelly)
    }

    private func launchEthereumUsdcSwap(extraScenarios: [ScenarioConfig] = []) {
        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            yieldApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: Constants.Scenario.networksProviders, initialState: Constants.State.ethereumProviderPair),
                ScenarioConfig(name: Constants.Scenario.userTokens, initialState: Constants.State.yieldUSDCEthereum),
                ScenarioConfig(name: Constants.Scenario.evmTokenBalances, initialState: Constants.State.nonZeroEvmBalances),
                ScenarioConfig(name: Constants.Scenario.expressAssets, initialState: Constants.State.yieldUSDCEthereumExchangeEnabled),
                ScenarioConfig(name: Constants.Scenario.ethereumPairs, initialState: Constants.State.ethUsdcChangelly),
            ] + extraScenarios
        )
    }

    private func waitForPortfolioBalances(_ mainScreen: MainScreen) {
        mainScreen
            .waitForTokenBalanceLoaded(tokenName: Constants.Token.ethereumName)
            .waitForTokenBalanceLoaded(tokenName: Constants.Token.usdcSymbol)
    }

    private func openSwapDeeplink(_ query: String) -> SwapScreen {
        safariHelper.safari.launch()
        safariHelper.openDeeplink("tangem://swap?\(query)")
        safariHelper.tapOpenButton()
        app.activate()
        return SwapStoriesScreen(app).closeStoriesIfNeeded()
    }
}

private extension SwapDeeplinksUITests {
    enum Constants {
        static let amount = "0.5"
        static let emptyAmountPlaceholder = "0"

        enum Token {
            static let ethereumName = "Ethereum"
            static let ethereumSymbol = "ETH"
            static let usdcSymbol = "USDC"
        }

        enum Provider {
            static let changelly = "Changelly"
        }

        enum Scenario {
            static let networksProviders = "networks_providers"
            static let userTokens = "user_tokens_api"
            static let evmTokenBalances = "moralis_evm_token_balances_api"
            static let expressAssets = "express_api_assets"
            static let ethereumPairs = "ethereum_pairs"
            static let exchangeQuoteEthereum = "exchange_quote_ethereum"
            static let ethNetworkBalance = "eth_network_balance"
        }

        enum State {
            static let ethereumProviderPair = "EthereumProviderPair"
            static let yieldUSDCEthereum = "YieldUSDCEthereum"
            static let nonZeroEvmBalances = "NonZeroEvmBalances"
            static let yieldUSDCEthereumExchangeEnabled = "YieldUSDCEthereumExchangeEnabled"
            static let ethUsdcChangelly = "EthUsdcChangelly"
            static let lessThanDollar = "LessThanDollar"
        }
    }
}
