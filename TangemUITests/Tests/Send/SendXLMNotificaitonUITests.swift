//
//  SendXRPNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendXLMNotificationUITests: BaseTestCase {
    private let coin = "Stellar"
    private let nonActivatedAddress = "GAGMMENFDWASIHSVO4BPVIT3ZH3YNUIM4EJ6MUDJW46OVPNOJSQIJ22K"
    private let activatedAddress = "GDKGS3UQFUNQY34P4SIAOKKGEA3NKHH6BSAXK4HIN3BZQQRBTITJLKL6"

    func testNotificationDisplayed_WhenSendingLessThanReserveToNonActivatedAccount() {
        setAllureId(4287)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.5")
            .tapNextButton()
            .enterDestination(nonActivatedAddress)
            .tapNextButton()
            .waitForInsufficientAmountToReserveAtDestinationBanner()
            .waitForSendButtonDisabled()
            .tapBackButton()
            .clearDestination()
            .enterDestination(activatedAddress)
            .tapNextButton()
            .waitForInsufficientAmountToReserveAtDestinationBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationNotDisplayed_WhenSendingAmountEqualToReserve() {
        setAllureId(4286)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("1")
            .tapNextButton()
            .enterDestination(nonActivatedAddress)
            .tapNextButton()
            .waitForInsufficientAmountToReserveAtDestinationBannerNotExists()
            .waitForSendButtonEnabled()
            .tapBackButton()
            .clearDestination()
            .enterDestination(activatedAddress)
            .tapNextButton()
            .waitForInsufficientAmountToReserveAtDestinationBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationNotDisplayed_WhenSendingAmountGreaterThanReserve() {
        setAllureId(4288)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("2")
            .tapNextButton()
            .enterDestination(nonActivatedAddress)
            .tapNextButton()
            .waitForInsufficientAmountToReserveAtDestinationBannerNotExists()
            .waitForSendButtonEnabled()
            .tapBackButton()
            .clearDestination()
            .enterDestination(activatedAddress)
            .tapNextButton()
            .waitForInsufficientAmountToReserveAtDestinationBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func prepareSendFlow() {
        let xlmScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XLM"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [xlmScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
