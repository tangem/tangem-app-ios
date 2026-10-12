//
//  SwapCommonUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapCommonUITests: BaseTestCase {
    private let token = "Polygon"
    private let fromTokenSymbol = "POL"
    private let receiveTokenSymbol = "ETH"
    private let alternativeToken = "Bitcoin"

    func testCheckSwapUI() {
        setAllureId(575)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)

        swapScreen
            .tapToTokenSelector()
            .selectToken(alternativeToken)
            .validateSwapScreenDisplayed()

        swapScreen
            .enterFromAmount("1")
            .waitForFromAmountValue("1")
            .clearFromAmount()

        swapScreen
            .waitForSwapTokensButtonDisplayed()
    }

    func testSwapButtonAvailability() {
        setAllureId(573)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "CustomTokenAndJesusAdded"),
            ]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen
            .tapToken("Polygon")
            .waitForSwapButtonEnabled()
            .goBackToMain()

        // Bitcoin has exchangeAvailable=false, but button is enabled — verify swap is unavailable on the swap screen
        mainScreen
            .tapToken("Bitcoin")
            .waitForSwapButtonEnabled()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .waitForConfirmButtonDisabled()
            .tapCloseButton()
            .goBackToMain()

        mainScreen
            .tapToken("Salam")
            .tapUnavailableSwapButton()

        waitAndDismissErrorAlert(actionName: "Swap", expectedMessage: "custom tokens")
    }

    func testSwapButtonNotDisplayedOnSingleCurrencyCards() {
        setAllureId(574)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xrpNote)
            .validate(cardType: .xrpNote)
            .waitForSwapButtonNotAvailable()
    }

    func testSwapTokensSwitch() {
        setAllureId(5162)

        launchApp(tangemApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .chooseReceiveToken("Ethereum")
            .waitToTokenDisplayed(tokenSymbol: receiveTokenSymbol)

        swapScreen
            .tapSwapTokensButton()

        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: receiveTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: fromTokenSymbol)
    }

    func testPredefinedPercentButtons() {
        setAllureId(9458)

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
            .tapToken("Ethereum")
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Polygon")

        swapScreen
            .tapAmountFraction("25")
            .waitForFromAmountValue("0.25")

        swapScreen
            .tapAmountFraction("50")
            .waitForFromAmountValue("0.5")

        swapScreen
            .tapAmountFraction("75")
            .waitForFromAmountValue("0.75")

        swapScreen
            .tapAmountFraction("max")
            .waitForFromAmountValue("1")
    }

    func testProviderTypeFilter() {
        setAllureId(9456)

        // Only the Ethereum-network POL pair has a DEX provider (1inch) alongside the CEX ones; the Polygon-network pair is CEX-only.
        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Ethereum")
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("POL (ex-MATIC)")

        swapScreen.enterFromAmount("0.1")

        let providerSelector = swapScreen
            .tapProviderBlock()
            .waitForDisplay()

        providerSelector
            .assertFilterDisplayed("all")
            .assertFilterDisplayed("cex")
            .assertFilterDisplayed("dex")

        providerSelector
            .selectFilter("dex")
            .selectProviderReturningToSwap(name: "1Inch")
            .verifyProviderName(contains: "1Inch")
    }
}
