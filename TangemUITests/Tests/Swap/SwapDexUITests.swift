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
                ScenarioConfig(name: "exchange_status_provider", initialState: "OneInchFinished"),
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

        // The swap status shown on the details screen comes from the transaction history list, not /v1/exchange-status.
        wireMockClient.setScenarioStateSync("exchange_history", state: "SwapFinished")
        pullToRefresh()

        let detailsSheet = tokenScreen
            .tapPendingExpressTransaction()
            .waitForDisplay()
            .assertProviderTitle(contains: "1Inch")

        detailsSheet
            .assertHeaderDateDisplayed()
            .assertHeaderTitle(contains: "Swapped")
            .assertLegAmountDisplayed(legId: "from")
            .assertLegAmountDisplayed(legId: "to")
            .assertRateRowDisplayed()

        detailsSheet
            .tapProviderRow()
            .waitForBrowserOpened()
    }
}
