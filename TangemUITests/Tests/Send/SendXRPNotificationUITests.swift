//
//  SendXRPNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendXRPNotificationUITests: BaseTestCase {
    private let coin = "XRP Ledger"
    private let nonActivatedAddress = "rvJfSnN6JzV3rhz1RRKDHnE6MYW28BaZG"
    private let activatedAddress = "rN7n7otQDd6FczFgLdSqtcsAUxDkw6fzRH"

    func testNotificationDisplayed_WhenSendingLessThanReserveToNonActivatedAccount() {
        setAllureId(4255)

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
        setAllureId(4285)

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
        setAllureId(4284)

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
        let xrpScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XRP"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [xrpScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
