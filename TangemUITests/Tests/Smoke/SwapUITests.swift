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

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .enterFromAmount(amountToEnter)
            .waitForFeeCalculation()
            .validateReceivedAmount()
    }

    func testChangeCommissionType_receivedAmountChanged() {
        setAllureId(3547)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .enterFromAmount(amountToEnter)
            .waitForFeeCalculation()
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.priority)
            .validateFeeChanged()
            .validateReceivedAmount()
    }

    func testSwapNoInternet_showConnectionError() {
        setAllureId(3549)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .enterFromAmount(amountToEnter)
            .waitErrorShown(title: "Error", message: "There was an error. Please try again.")
    }
}
