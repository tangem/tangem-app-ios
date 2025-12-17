//
//  SendPolkadotNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendPolkadotNotificationUITests: BaseTestCase {
    private let coin = "Polkadot"
    private let destinationAddress = "143TfgFYAFfM86LRzt4UcFNU3KosxCndBCVz2U5HCxpLidKZ"

    func testPolkadotDepositWarningNotification() {
        setAllureId(4289)

        prepareSendFlow()

        // the remaining balance is less than the required deposit
        let sendScreen = SendScreen(app)
            .waitForDisplay()
            .enterAmount("1.299")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForExistentialDepositWarningBanner()
            .waitForSendButtonDisabled()

        // "leave deposit" button
        sendScreen
            .tapLeaveAmountButton()
            .waitForExistentialDepositWarningBannerNotExists()
            .waitForSendButtonEnabled()

        // the remaining balance is greater than the deposit
        sendScreen
            .tapFromWalletButton()
            .clearAmount()
            .enterAmount("0.2")
            .tapNextButton()
            .waitForExistentialDepositWarningBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func prepareSendFlow() {
        let polkadotTokenScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Polkadot"
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Polkadot"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [polkadotTokenScenario, quotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
