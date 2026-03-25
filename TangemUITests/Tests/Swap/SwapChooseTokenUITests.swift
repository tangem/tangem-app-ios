//
//  SwapChooseTokenUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapChooseTokenUITests: BaseTestCase {
    func testAvailableToSwapTokensList() {
        setAllureId(8505)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "CustomTokenAndJesusAdded"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("POL (ex-MATIC)")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        let tokenSelector = swapScreen
            .enterFromAmount("100")
            .tapToTokenSelector()
            .waitSwapTokenSelectorDisplayed()

        tokenSelector
            .waitForTokenAvailable("Ethereum")
            .waitForTokenAvailable("POL (ex-MATIC)")

        tokenSelector
            .waitForTokenUnavailable("Bitcoin")
            .waitForTokenUnavailable("Jesus Coin")
            .waitForTokenUnavailable("Salam")
    }

    func testSearchOnChooseTokenScreen() {
        setAllureId(8506)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Polygon")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        let tokenSelector = swapScreen
            .enterFromAmount("100")
            .tapToTokenSelector()
            .waitSwapTokenSelectorDisplayed()

        tokenSelector
            .typeSearchText("f")
            .waitForTokenNotDisplayed("Ethereum")
            .waitForTokenNotDisplayed("POL (ex-MATIC)")

        tokenSelector
            .clearSearchText()
            .typeSearchText("pol")
            .waitForTokenDisplayed("POL (ex-MATIC)")
            .waitForTokenNotDisplayed("Ethereum")

        tokenSelector
            .selectToken("POL (ex-MATIC)")
            .validateSwapScreenDisplayed()
            .waitToTokenDisplayed(tokenSymbol: "POL")
    }
}
