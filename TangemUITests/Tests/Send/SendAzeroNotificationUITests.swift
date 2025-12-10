//
//  SendAzeroNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendAzeroNotificationUITests: BaseTestCase {
    private let coin = "Aleph Zero"
    private let destinationAddress = "5EA4p6DZdbt2vLZySML2dG3ZsnNrenEWZHnVCScQh4iq2KZo"

    func testAzeroDepositWarningNotification() {
        setAllureId(4290)

        prepareSendFlow()

        // the remaining balance is less than the required deposit
        let sendScreen = SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.099876587544")
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
            .enterAmount("0.09")
            .tapNextButton()
            .waitForExistentialDepositWarningBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func prepareSendFlow() {
        let alephZeroTokenScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Aleph Zero"
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Aleph Zero"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [alephZeroTokenScenario, quotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
