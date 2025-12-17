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

    func testNotificationDisplayed_WhenSendingMaximumAmount() throws {
        setAllureId(4229)

        prepareSendFlow()

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

    func testNotificationNotDisplayed_WhenSendingNonMaximumAmount() throws {
        setAllureId(4230)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.1")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForHighFeeNotificationBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func prepareSendFlow() {
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

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
