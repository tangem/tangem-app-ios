//
//  SendChiaNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class SendChiaNotificationUITests: BaseTestCase {
    private let coin = "Chia Network"
    private let destinationAddress = "xch1dz2vua2qvxpx6fufd98rxxv2n8j9t3au733xlht3fga4gk8ks5mqq5tzsz"
    private let amount = "0.85"

    func testNoBanner_WhenTop15CoversAmount_LessThan15() {
        setAllureId(4226)

        openSend(initialState: "less_than_15")

        SendScreen(app)
            .waitForDisplay()
            .enterAmount(amount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForAmountExceedMaximumUTXOBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNoBanner_WhenTop15CoversAmount_Exactly15() {
        setAllureId(4227)

        openSend(initialState: "equal_15")

        SendScreen(app)
            .waitForDisplay()
            .enterAmount(amount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForAmountExceedMaximumUTXOBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testBannerShown_WhenRequiredInputsExceed15() {
        setAllureId(4228)

        openSend(initialState: "more_than_15")

        SendScreen(app)
            .waitForDisplay()
            .enterAmount(amount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForAmountExceedMaximumUTXOBanner()
            .waitForSendButtonDisabled()
    }

    private func openSend(initialState: String) {
        let chiaTokenScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Chia"
        )
        let chiaGetCoinsScenario = ScenarioConfig(
            name: "chia_get_coin_records",
            initialState: initialState
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Chia"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [chiaTokenScenario, chiaGetCoinsScenario, quotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
