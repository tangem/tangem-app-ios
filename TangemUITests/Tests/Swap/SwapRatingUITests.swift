//
//  SwapRatingUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapRatingUITests: BaseTestCase {
    func testRateSwapExperience() {
        setAllureId(9986)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "PolygonUSDCHotWallet"),
                ScenarioConfig(name: "quotes_api", initialState: "PolygonUSDC"),
                ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
                ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
                ScenarioConfig(name: "polygon_coin_balance", initialState: "ZeroBalance"),
            ]
        )

        importHotWallet()
            .tapToken("USDC")
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Polygon")
            .enterFromAmount("50")
            .assertNetworkFeeBlockDisplayed()
            .confirmSwap()

        let tokenScreen = SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()
            .waitForPendingExpressTransaction()

        let expressStatusSheet = tokenScreen.tapPendingExpressTransaction()

        let statusSheet = expressStatusSheet
            .waitForDisplay()
            .assertRatingBlockDisplayed()

        let feedbackScreen = statusSheet
            .tapStar(5)

        feedbackScreen
            .waitForDisplay()
            .assertSubmitButtonDisplayed()
            .enterFeedback("Great swap experience")
            .tapSubmitButton()
            .assertStarNotTappable(5)
    }
}
