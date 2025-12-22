//
//  SendKusamaNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendKusamaNotificationUITests: BaseTestCase {
    private let coin = "Kusama"
    private let destinationAddress = "CqNrR92Hh76vW69vDBL5iATrZoYkk9nj67iVSUbb2YHtktn"

    func testKusamaDepositWarningNotification() {
        setAllureId(4291)

        prepareSendFlow()

        // the remaining balance is less than the required deposit
        let sendScreen = SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.300333")
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
            .enterAmount("0.1")
            .tapNextButton()
            .waitForExistentialDepositWarningBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func prepareSendFlow() {
        let kusamaTokenScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Kusama"
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Kusama"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [kusamaTokenScenario, quotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
