//
//  SwapFeeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapFeeUITests: BaseTestCase {
    private let notEnoughFeeTitle = "Unable to cover Ethereum fee"
    private let notEnoughFeeMessage = "To make a transaction you need to deposit some Ethereum ETH"

    func testEnableToCoverMarketAndFastFee() {
        setAllureId(583)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("Ethereum")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .enterFromAmount("0.99")

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.normal)
            .validateFeeChanged()
            .waitForFeeAmountDisplayed()

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.priority)
            .validateFeeChanged()
            .waitForFeeAmountDisplayed()
    }

    func testUnableToCoverMarketAndFastFee() {
        setAllureId(8536)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "eth_network_balance", initialState: "LessThanDollar"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("POL (ex-MATIC)")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .enterFromAmount("0.0001")

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.normal)
            .validateFeeChanged()
            .waitForNotificationShown(title: notEnoughFeeTitle, message: notEnoughFeeMessage)
            .waitForConfirmButtonDisabled()

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.priority)
            .validateFeeChanged()
            .waitForNotificationShown(title: notEnoughFeeTitle, message: notEnoughFeeMessage)
            .waitForConfirmButtonDisabled()
    }

    func testUnableToCoverFastFeeOnly() {
        setAllureId(8537)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [
                ScenarioConfig(name: "eth_fee_history", initialState: "UnableToCoverFastFee"),
            ]
        )

        let swapScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("POL (ex-MATIC)")
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()

        swapScreen
            .enterFromAmount("3000")
            .waitForConfirmButtonEnabled()

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.priority)
            .validateFeeChanged()
            .waitForNotificationShown(title: notEnoughFeeTitle, message: notEnoughFeeMessage)
            .waitForConfirmButtonDisabled()

        swapScreen
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.normal)
            .validateFeeChanged()
            .waitForNotificationNotShown()
            .waitForConfirmButtonEnabled()
    }
}
