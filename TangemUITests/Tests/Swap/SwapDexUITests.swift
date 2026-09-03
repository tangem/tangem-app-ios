//
//  SwapDexUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapDexUITests: BaseTestCase {
    func testDexSwapStatusBlock() {
        setAllureId(9459)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "HotWalletSvS"),
                ScenarioConfig(name: "quotes_api", initialState: "PolygonUSDC"),
                ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
                ScenarioConfig(name: "ethereum_from_pairs", initialState: "DexProvider"),
                ScenarioConfig(name: "exchange_status_provider", initialState: "OneInch"),
            ]
        )

        importHotWallet()
            .tapToken("POL (ex-MATIC)")
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Ethereum")
            .enterFromAmount("50")
            .assertNetworkFeeBlockDisplayed()
            .confirmSwap()

        let tokenScreen = SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()
            .waitForPendingExpressTransaction()

        tokenScreen
            .tapPendingExpressTransaction()
            .waitForDisplay()
            .assertProviderTitle(contains: "1Inch")
    }
}
