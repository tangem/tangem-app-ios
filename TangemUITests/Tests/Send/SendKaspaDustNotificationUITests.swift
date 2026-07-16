//
//  SendKaspaDustNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendKaspaDustNotificationUITests: BaseTestCase {
    private let coin = "Kaspa"
    private let destinationAddress = "kaspa:qypc4aywf95rken57kclwdjvycugnacstrh5uzmu0a7pjtxas366ktgj5jzu8t6"

    func testNotificationDisplayed_WhenSendingLessThanMinimumAmount() {
        setAllureId(4685)

        openSend()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.1")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBanner()
            .waitForSendButtonDisabled()
    }

    func testNotificationNotDisplayed_WhenSendingExactlyMinimumAmount() {
        setAllureId(9860)

        openSend()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.2")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationNotDisplayed_WhenSendingMoreThanMinimumAmount() {
        setAllureId(4683)

        openSend()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.3")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationNotDisplayed_WhenRemainingAmountIsMoreThanMinimumAmount() {
        setAllureId(4684)

        openSend()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.5")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationDisplayed_WhenRemainingAmountIsLessThanMinimumAmount() {
        setAllureId(4682)

        openSend()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.85")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBanner()
            .waitForSendButtonDisabled()
    }

    func testNotificationNotDisplayed_WhenRemainingAmountIsExactlyMinimumAmount() {
        setAllureId(9861)

        openSend()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.79")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func openSend() {
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
            initialState: "dust"
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
