//
//  TotalBalanceSmokeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class TotalBalanceSmokeUITests: BaseTestCase {
    func testTotalBalanceDisplayed_BeforeAndAfterPullToRefresh() {
        setAllureId(150)
        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
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

        let appSettingsScreen = CreateWalletSelectorScreen(app)
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

        let mainScreen = CreateWalletSelectorScreen(app)
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

        let mainScreen = CreateWalletSelectorScreen(app)
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

        let tokenBalance = CreateWalletSelectorScreen(app)
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

        CreateWalletSelectorScreen(app)
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

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceShimmer()
            .waitForTotalBalanceDisplayed()
    }

    func testSynchronizeAddressesButtonExistsAndTotalBalanceShowsDash() {
        setAllureId(148)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet)
            .waitForSynchronizeAddressesButtonExists()
            .waitForTotalBalanceDisplayedAsDash()
    }

    func testEthNetworkBalanceUnreachable_TotalBalanceDisplayedAsDash() {
        setAllureId(3993)

        let ethNetworkBalanceScenario = ScenarioConfig(
            name: "eth_network_balance",
            initialState: "Unreachable"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [ethNetworkBalanceScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceDisplayedAsDash()
    }

    func testStakingBalanceCalculation_POLToken() throws {
        setAllureId(166)

        let stakingScenario = ScenarioConfig(
            name: "staking_eth_pol_balances_ios",
            initialState: "Staked"
        )

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            scenarios: [stakingScenario]
        )

        let tokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("POL (ex-MATIC)")

        let totalBalanceValue = try XCTUnwrap(Double(tokenScreen.getTotalBalance().replacingOccurrences(of: "$", with: "")))
        let stakingBalanceValue = try XCTUnwrap(Double(tokenScreen.getStakingBalance().replacingOccurrences(of: "$", with: "")))

        tokenScreen.tapAvailableSegment()

        let availableBalanceValue = try XCTUnwrap(Double(tokenScreen.getAvailableBalance().replacingOccurrences(of: "$", with: "")))

        XCTAssertEqual(
            totalBalanceValue,
            stakingBalanceValue + availableBalanceValue,
            accuracy: 0.01,
            "Total balance should equal staking balance + available balance"
        )
    }

    func testSearchAndAddXRPToPortfolio() throws {
        setAllureId(3997)

        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Ripple"
        )
        let tokensScenario = ScenarioConfig(
            name: "wallet_tokens_api",
            initialState: "XRP"
        )
        let expectedBalance = Decimal(3320.46)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [quotesScenario, tokensScenario]
        )

        let marketsScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken("XRP")
            .tapTokenInSearchResults("XRP")

        setupWireMockScenarios([quotesScenario, tokensScenario])

        let mainScreen = marketsScreen
            .tapAddToPortfolioButton()
            .selectNetwork("XRP Ledger")
            .tapAddTokenButton()
            .tapGetTokenLaterButton()
            .closeMarketsSheetWithSwipe()

        let actualBalance = mainScreen.getTotalBalanceNumericValue()

        XCTAssertEqual(actualBalance, expectedBalance, "Expected balance \(expectedBalance) does not match actual balance \(actualBalance)")
    }

    func testHidePolygonToken_TotalBalanceDecreases() {
        let token = "Polygon"
        setAllureId(4002)
        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceDisplayed()

        let initialBalance = mainScreen.getTotalBalanceNumericValue()

        let tokenScreen = mainScreen.longPressToken(token)
        tokenScreen
            .tapHideToken(tokenName: token)
            .verifyTotalBalanceDecreased(from: initialBalance)
    }

    func testTotalBalanceZero_AllTokensZeroExceptSuperCustomTokenDash() {
        setAllureId(164)
        let customToken = "SuperCustomToken"

        let userTokensScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "TOTAL_BALANCE_TOKENS_ZERO"
        )

        let rippleAccountInfoScenario = ScenarioConfig(
            name: "ripple_account_info",
            initialState: "Empty"
        )

        let ethCallScenario = ScenarioConfig(
            name: "eth_call_api",
            initialState: "Empty"
        )

        let ethNetworkBalance = ScenarioConfig(
            name: "eth_network_balance",
            initialState: "Empty"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [userTokensScenario, rippleAccountInfoScenario, ethCallScenario, ethNetworkBalance]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceDisplayed()

        let totalBalance = mainScreen.getTotalBalanceNumericValue()
        XCTAssertEqual(totalBalance, 0, "Total balance should equal 0, but got: \(totalBalance)")

        let tokensOrder = mainScreen.getTokensOrder()
        let tokenNames = tokensOrder.allTokensFlat
        for tokenName in tokenNames {
            if tokenName == customToken {
                let balances = mainScreen.getAllTokenBalances(tokenName: tokenName)
                for balance in balances {
                    XCTAssertEqual(balance, "–", "\(customToken) should display dash symbol, but got: \(balance)")
                }
            } else {
                let numericBalances = mainScreen.getAllTokenBalancesNumeric(tokenName: tokenName)
                for value in numericBalances {
                    XCTAssertEqual(value, 0, "Token '\(tokenName)' should have 0.00 balance, but got: \(value)")
                }
            }
        }
    }

    func testTotalBalancePositive_AllTokensPositiveExceptSuperCustomTokenDash() {
        setAllureId(3966)
        let customToken = "SuperCustomToken"

        let userTokensScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "TOTAL_BALANCE_TOKENS_POSITIVE"
        )

        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Ripple"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [userTokensScenario, quotesScenario]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .waitForTotalBalanceDisplayed()

        let totalBalance = mainScreen.getTotalBalanceNumericValue()
        XCTAssertGreaterThan(totalBalance, 0, "Total balance should be positive, but got: \(totalBalance)")

        let tokensOrder = mainScreen.getTokensOrder()
        let tokenNames = tokensOrder.allTokensFlat

        for tokenName in tokenNames {
            if tokenName == customToken {
                let balances = mainScreen.getAllTokenBalances(tokenName: tokenName)
                for balance in balances {
                    XCTAssertEqual(balance, "–", "\(customToken) should display dash symbol, but got: \(balance)")
                }
            } else {
                let numericBalances = mainScreen.getAllTokenBalancesNumeric(tokenName: tokenName)
                for value in numericBalances {
                    XCTAssertGreaterThan(value, 0, "Token '\(tokenName)' should have positive balance, but got: \(value)")
                }
            }
        }
    }

    func testLongPressWalletHeader_NoDeleteButton() {
        setAllureId(3965)
        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressWalletHeader()

        mainScreen.waitForNoDeleteButton()
    }
}
