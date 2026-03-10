//
//  SwapSearchUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapSearchUITests: BaseTestCase {
    func testSearchAndSwap_AddTokenWithDerivation() {
        setAllureId(8519)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainSwap()
            .closeStoriesIfNeededAndReturnToTokenSelector()
            .selectFromToken(Constants.Token.ethereum)
            .typeSearchText(Constants.Search.trx)
            .selectMarketToken(Constants.Token.tron)
            .tapAddTokenButton()
            .waitForTokenAddedToast()
            .validateSwapScreenDisplayed()
            .waitToTokenDisplayed(tokenSymbol: Constants.Symbol.trx)
    }

    func testSearchAndSwap_AddTokenWithoutDerivation() {
        setAllureId(8520)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainSwap()
            .closeStoriesIfNeededAndReturnToTokenSelector()
            .selectFromToken(Constants.Token.polygon)
            .typeSearchText(Constants.Search.tether)
            .selectMarketToken(Constants.Token.tether)
            .tapAddTokenButton()
            .waitForTokenAddedToast()
            .validateSwapScreenDisplayed()
            .waitToTokenDisplayed(tokenSymbol: Constants.Symbol.usdt)
    }

    func testSearchAndSwap_SearchTokenFromInsideSwapScreen() {
        setAllureId(8521)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Token.ethereum)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .tapSwapTokensButton()
            .tapFromTokenSelector()
            .typeSearchText(Constants.Search.xrp)
            .selectMarketToken(Constants.Token.xrp)
            .tapAddTokenButton()
            .waitForTokenAddedToast()
            .validateSwapScreenDisplayed()
            .waitFromTokenDisplayed(tokenSymbol: Constants.Symbol.xrp)
    }

    func testSearchAndSwap_UnsupportedTokenPairBanner() {
        setAllureId(8522)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainSwap()
            .closeStoriesIfNeededAndReturnToTokenSelector()
            .selectFromToken(Constants.Token.ethereum)
            .typeSearchText(Constants.Search.pepe)
            .selectMarketToken(Constants.Token.pepe)
            .tapAddTokenButton()
            .waitForTokenAddedToast()
            .validateSwapScreenDisplayed()
            .waitForNotificationShown(title: Constants.unsupportedSwapPairTitle)
    }

    func testSearchAndSwap_TrendingNowErrorState() {
        setAllureId(8523)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.coinsList, initialState: Constants.Scenario.errorState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainSwap()
            .closeStoriesIfNeededAndReturnToTokenSelector()
            .waitSwapTokenSelectorDisplayed()
            .waitForTrendingNowError()
            .waitForRetryButtonDisplayed()
    }
}

private extension SwapSearchUITests {
    enum Constants {
        enum Token {
            static let ethereum = "Ethereum"
            static let polygon = "Polygon"
            static let tron = "TRON"
            static let tether = "Tether"
            static let xrp = "XRP"
            static let pepe = "Pepe"
        }

        enum Symbol {
            static let trx = "TRX"
            static let usdt = "USDT"
            static let xrp = "XRP"
        }

        enum Search {
            static let trx = "TRX"
            static let tether = "Tether"
            static let xrp = "XRP"
            static let pepe = "Pepe"
        }

        enum Network {
            static let ethereum = "Ethereum"
            static let tron = "TRON"
            static let xrpLedger = "XRP Ledger"
        }

        enum Scenario {
            static let coinsList = "coins_list_api"
            static let errorState = "Error"
        }

        static let unsupportedSwapPairTitle = "Unsupported swap pair"
    }
}
