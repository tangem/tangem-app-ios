//
//  SendKaspaNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendKaspaNotificationUITests: BaseTestCase {
    private let coin = "Kaspa"
    private let destinationAddress = "kaspa:qypc4aywf95rken57kclwdjvycugnacstrh5uzmu0a7pjtxas366ktgj5jzu8t6"

    func testNotificationNotDisplayed_WhenSenderHasLessThan84Inputs() {
        setAllureId(4223)

        openSend(initialState: "less_than_84")

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.3")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForAmountExceedMaximumUTXOBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationNotDisplayed_WhenSenderHasExactly84Inputs() {
        setAllureId(4224)

        openSend(initialState: "equal_84")

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.3")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForAmountExceedMaximumUTXOBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationDisplayed_WhenSenderHasMoreThan84Inputs() {
        setAllureId(4225)

        openSend(initialState: "more_than_84")

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.85")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForAmountExceedMaximumUTXOBanner()
            .waitForSendButtonDisabled()
    }

    private func openSend(initialState: String) {
        let kaspaTokenScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Kaspa"
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Kaspa"
        )
        let kaspaUtxoScenario = ScenarioConfig(
            name: "kaspa_utxo",
            initialState: initialState
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [kaspaTokenScenario, kaspaUtxoScenario, quotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
