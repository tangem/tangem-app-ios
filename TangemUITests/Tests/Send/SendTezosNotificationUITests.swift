//
//  SendTezosNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendTezosNotificationUITests: BaseTestCase {
    private let coin = "Tezos"
    private let destinationAddress = "tz1eBdC2JkU2bxgZssweLo6D3wCkWN12ioHW"

    override func setUp() {
        super.setUp()

        let tezosTokenScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Tezos"
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Tezos"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [tezosTokenScenario, quotesScenario]
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }

    func testNotificationDisplayed_WhenSendingMaximumAmount() {
        setAllureId(4229)

        let sendScreen = SendScreen(app)
            .waitForDisplay()
            .tapMaxButton()

        let amountBeforeReduceFee = sendScreen.getAmountNumericValue()

        sendScreen
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForHighFeeNotificationBanner()
            .waitForSendButtonEnabled()
            .reduceFee()
            .waitForSendButtonEnabled()
            .tapBackButton()
            .tapBackButton()
            .validateAmountDecreased(from: amountBeforeReduceFee)
    }

    func testNotificationNotDisplayed_WhenSendingNonMaximumAmount() {
        setAllureId(4230)

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.1")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForHighFeeNotificationBannerNotExists()
            .waitForSendButtonEnabled()
    }
}
