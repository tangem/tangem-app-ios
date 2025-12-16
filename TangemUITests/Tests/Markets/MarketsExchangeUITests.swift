//
//  MarketsExchangeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class MarketsExchangeUITests: BaseTestCase {
    func testMarketsExchangesList() {
        setAllureId(58)
        let tokenName = "Solana"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .openExchanges()
            .verifyExchangesListScreen()
    }

    func testMarketsExchangesBlockDisplayed() {
        setAllureId(56)
        let tokenName = "Bitcoin"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .verifyListedOnExchangesBlock()
            .openExchanges()
            .verifyExchangesListScreen()
    }

    func testMarketsExchangesListSortedByVolume() {
        setAllureId(60)
        let tokenName = "Bitcoin"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .openExchanges()
            .verifyExchangesListSortedByVolume()
    }

    func testMarketsExchangesType() {
        setAllureId(61)
        let tokenName = "Bitcoin"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .openExchanges()
            .verifyExchangeTypes()
    }

    func testMarketsExchangesTrustScore() {
        setAllureId(62)
        let tokenName = "Bitcoin"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .openExchanges()
            .verifyExchangeTrustScore()
    }

    func testMarketsExchangesEmpty() {
        setAllureId(57)
        let tokenName = "Bitcoin"

        let bitcoinScenario = ScenarioConfig(
            name: "coins_bitcoin",
            initialState: "EmptyExchanges"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [bitcoinScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .verifyListedOnExchangesBlockEmpty()
    }

    func testMarketsExchangesErrorState() {
        setAllureId(59)
        let tokenName = "Bitcoin"

        let exchangeScenarioUnreachable = ScenarioConfig(
            name: "bitcoin_exchange",
            initialState: "Unreachable"
        )

        let exchangeScenario = ScenarioConfig(
            name: "bitcoin_exchange",
            initialState: "Started"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [exchangeScenarioUnreachable]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .openExchanges()
            .verifyUnableToLoadData()

        setupWireMockScenarios([exchangeScenario])

        MarketsExchangeScreen(app)
            .tapTryAgain()
            .verifyExchangesListScreen()
    }
}
