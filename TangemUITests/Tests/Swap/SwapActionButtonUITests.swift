//
//  SwapActionButtonUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapActionButtonUITests: BaseTestCase {
    private let token = "Ethereum"
    private let fromTokenSymbol = "ETH"
    private let receiveToken = "Polygon"
    private let receiveTokenSymbol = "POL"

    func testSwapFromTokenDetails_NavigatesToSwapScreen() {
        setAllureId(2828)

        launchApp(tangemApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .waitForSwapButtonEnabled()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)

        swapScreen
            .enterFromAmount("1")
            .waitForFromAmountValue("1")
    }

    func testSwapFromMainScreen_OpensTokenSelectorAndSwapScreen() {
        setAllureId(2829)

        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        let swapScreen = mainScreen
            .tapMainSwap()
            .closeStoriesIfNeededAndReturnToTokenSelector()
            .waitSwapTokenSelectorDisplayed()
            .selectToken(token)

        swapScreen
            .selectReceiveToken(receiveToken)
            .validateSwapScreenDisplayed()
            .waitFromTokenDisplayed(tokenSymbol: fromTokenSymbol)
            .waitToTokenDisplayed(tokenSymbol: receiveTokenSymbol)

        swapScreen
            .enterFromAmount("1")
            .waitForFromAmountValue("1")
    }
}
