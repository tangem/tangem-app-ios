//
//  SendSolanaNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendSolanaNotificationUITests: BaseTestCase {
    private let coin = "Solana"
    private let destinationAddress = "5fcy9woa8Di1QHcce65CsV3XKrxdB2pD4HJx5xx82ipM"

    func testNotificationDisplayed_WhenBalanceAfterSendingLessThanRentFee() {
        setAllureId(564)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.0016941")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForRemainingAmountIsLessThanRentExemptionBanner()
            .waitForSendButtonDisabled()
    }

    func testNotificationNotDisplayed_WhenBalanceAfterSendingEqualsZero() {
        setAllureId(565)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .tapMaxButton()
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForRemainingAmountIsLessThanRentExemptionBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationNotDisplayed_WhenBalanceAfterSendingEqualsRentFee() {
        setAllureId(566)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.001689338")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForRemainingAmountIsLessThanRentExemptionBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testNotificationNotDisplayed_WhenBalanceAfterSendingGreaterThanRentFee() {
        setAllureId(567)

        prepareSendFlow()

        SendScreen(app)
            .waitForDisplay()
            .enterAmount("0.0000941")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForRemainingAmountIsLessThanRentExemptionBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func prepareSendFlow() {
        let solanaTokenScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Solana"
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Solana"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [solanaTokenScenario, quotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(coin)
            .tapSendButton()
    }
}
