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
        id(3546)

        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .validateSwapScreenDisplayed()
            .enterFromAmount(amountToEnter)
            .waitForFeeCalculation()
            .validateReceivedAmount()
    }

    func testChangeCommissionType_receivedAmountChanged() {
        id(3547)

        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapSwapButton()
            .validateSwapScreenDisplayed()
            .enterFromAmount(amountToEnter)
            .waitForFeeCalculation()
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.priority)
            .validateFeeChanged()
            .validateReceivedAmount()
    }
}
