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

        launchApp(tangemApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: receiveTokenSymbol)

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
            .waitForConfirmButtonDisabled()
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
            .waitForSwapButtonDisabled()
            .goBackToMain()
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
            .waitToTokenDisplayed(tokenSymbol: receiveTokenSymbol)

        swapScreen
            .tapSwapTokensButton()

        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: receiveTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: fromTokenSymbol)
    }
}
