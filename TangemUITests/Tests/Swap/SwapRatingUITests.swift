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
                ScenarioConfig(name: Constants.exchangeStatusScenario, initialState: Constants.pendingState),
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

        let statusSheet = tokenScreen
            .tapPendingExpressTransaction()
            .waitForDisplay()

        // Only a finished swap is rateable, and a finished one leaves the token screen, so the status is flipped here.
        wireMockClient.setScenarioStateSync(Constants.exchangeStatusScenario, state: Constants.finishedState)

        statusSheet
            .assertRatingBlockDisplayed()
            .tapStar(5)
            .waitForDisplay()
            .assertSubmitButtonDisplayed()
            .enterFeedback("Great swap experience")
            .tapSubmitButton()
            .assertStarNotTappable(5)
    }
}

private extension SwapRatingUITests {
    enum Constants {
        static let exchangeStatusScenario = "exchange_status_provider"
        static let pendingState = "Changelly"
        static let finishedState = "Finished"
    }
}
