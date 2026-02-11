//
//  MarketsSearchUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class MarketsSearchUITests: BaseTestCase {
    func testMarketsSearch_ByTicker() {
        setAllureId(37)
        let ticker = "BTC"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(ticker)
            .verifyAllVisibleSearchResultsCurrencyContains(ticker)
    }

    func testMarketsSearch_ByTokenName() {
        setAllureId(36)
        let query = "Wrapped"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(query)
            .verifyAllVisibleSearchResultsTokenNameContains(query)
    }

    func testMarketsSearch_TokensUnderCap_CollapsedAndExpandable() {
        setAllureId(40)
        let query = "kok"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(query)
            .tapShowTokensUnderCapButton()
            .verifyAllVisibleSearchResultsTokenNameContains(query)
    }

    func testMarketsSearch_NoResultsState_Displayed() {
        setAllureId(41)
        let query = "rublo"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(query)
            .verifyNoResultsStateIsDisplayed()
    }

    func testMarketsSearch_DefaultList_First10Order_FromAPI() {
        setAllureId(39)

        let expected = [
            "Bitcoin",
            "Ethereum",
            "Tether",
            "XRP",
            "BNB",
            "Solana",
            "USDC",
            "TRON",
            "Dogecoin",
            "Lido Staked Ether",
        ]

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .verifyFirstCoinsOrder(expected)
    }

    func testMarketsSearch_BySmartContractAddress() {
        setAllureId(38)
        let network = "ETHEREUM"
        let managedToken = "Tether  USDT"
        let expectedMarketsToken = "Tether"

        launchApp()

        let manageTokens = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .openManageTokens()

        let mainScreen = manageTokens
            .expandTokenIfNeeded(managedToken)
            .ensureNetworkSelected(network)
            .longPressNetworkToCopy(network, duration: 1.0)
            .goBackToWalletSettings()
            .goBackToDetails()
            .goBackToMain()

        mainScreen
            .openMarketsSheetWithSwipe()
            .pasteIntoSearchField()
            .verifyTokenInSearchResults(expectedMarketsToken)
    }

    func testMarketsSearch_Actions_TypeDeleteClear() {
        setAllureId(35)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .tapSearchFieldAndVerifyKeyboard()
            .typeInSearchField("b")
            .verifyAllVisibleSearchResultsTokenNameContains("b")
            .typeInSearchField("tc")
            .verifyAllVisibleSearchResultsCurrencyContains("BTC")
            .deleteSearchCharacters(1)
            .verifyAllVisibleSearchResultsTokenNameContains("bt")
            .clearSearchField()
            .verifySearchFieldIsEmptyAndClearButtonHidden()
    }
}
