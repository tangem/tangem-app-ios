//
//  SendNotificationDogecoinUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendNotificationDogecoinUITests: BaseTestCase {
    private let destinationAddress = "DJQR3bdhBKcFGMHX2BkMCkrMFApNWNzr6V"
    private let coin = "Dogecoin"

    func testNotificationNotDisplayed_WhenSendingMoreThan001DOGE() {
        setAllureId(4211)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.02")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationDisplayed_WhenSendingLessThan001DOGE() {
        setAllureId(4212)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.005")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBanner()
            .waitForSendButtonDisabled()
    }

    func testNotificationDisplayed_WhenLessThan001DOGERemainsAfterSending() throws {
        setAllureId(4213)

        try skipDueToBug("[REDACTED_INFO]", description: "Send: fee error when sending Dogecoin")

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("9.995")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBanner()
            .waitForSendButtonDisabled()
    }

    func testNotificationNotDisplayed_WhenMoreThan001DOGERemainsAfterSending() throws {
        setAllureId(4214)

        try skipDueToBug("[REDACTED_INFO]", description: "Send: fee error when sending Dogecoin")

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("9")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func prepareSendFlow() {
        let dogecoinScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Dogecoin"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [dogecoinScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
