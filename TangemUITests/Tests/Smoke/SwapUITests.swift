//
//  SwapUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class SwapUITests: BaseTestCase {
    let token = "Polygon"
    let amountToEnter = "100"

    func testSwapCommission_validateReceivedAmount() {
        setAllureId(3546)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Ethereum")

        swapScreen
            .enterFromAmount(amountToEnter)
            .waitForFeeCalculation()
            .validateReceivedAmount()

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .waitForFeeOptionSelected(.normal)
            .waitForFeeOptionNotSelected(.priority)
            .selectFeeOption(.normal)
            .validateFeeChanged()

        let initialReceiveAmount = swapScreen.captureReceiveAmount()

        swapScreen
            .enterFromAmount("10")
            .waitForFeeAmountDisplayed()
            .validateReceivedAmount()
            .assertReceiveAmount(notEquals: initialReceiveAmount)
    }

    func testChangeCommissionType_receivedAmountChanged() {
        setAllureId(3547)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Ethereum")

        swapScreen
            .enterFromAmount(amountToEnter)
            .waitForFeeCalculation()
            .validateReceivedAmount()

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .waitForFeeOptionSelected(.normal)
            .waitForFeeOptionNotSelected(.priority)
            .assertFeeOptionsHaveDifferentFees()
            .selectFeeOption(.priority)
            .validateFeeChanged()

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .waitForFeeOptionSelected(.priority)
            .waitForFeeOptionNotSelected(.normal)
            .selectFeeOption(.normal)
            .validateFeeChanged()
    }

    func testSwapNoInternet_showConnectionError() {
        setAllureId(3549)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "exchange_quote_polygon", initialState: "Unreachable"),
            ]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken("Ethereum")
            .enterFromAmount(amountToEnter)
            .waitErrorShown(title: "Error", message: "There was an error. Please try again.")
    }
}
