//
//  SendCardanoNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class SendCardanoNotificationUITests: BaseTestCase {
    private let network = "Cardano"
    private let destinationAddress = "addr1q8tl5q2al97clkvht3x5wa0fsxtsn60h69qv3z9qzjk97acl8vc4df3r6c4xz9a4lj9388fkazw4na6t7yx8x6mvw32qsmvtwy"
    private var cardanoScenario: ScenarioConfig!

    func testAfterTransacitonRemainsLessThanMinimumAmount_ShowsNotificationAndSendDisabled() {
        setAllureId(4204)
        let transactionAmount = "19"

        prepareSendFlow()

        SendScreen(app)
            .enterAmount(transactionAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBanner()
            .waitForSendButtonDisabled()
    }

    func testTransactionAmountMoreThanOne_NoNotification_SendEnabled() {
        setAllureId(4207)
        let transactionAmount = "2.5"

        prepareSendFlow()

        SendScreen(app)
            .enterAmount(transactionAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBannerNotExists()
            .waitForSendButtonEnabled()
    }

    func testRemainingAmountMoreThanOne_NoNotification_SendEnabled() {
        setAllureId(4210)
        let transactionAmount = "18"

        prepareSendFlow()

        SendScreen(app)
            .enterAmount(transactionAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBannerNotExists()
            .waitForSendButtonEnabled()
    }

    private func prepareSendFlow() {
        cardanoScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: network
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [cardanoScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(network)
            .tapActionButton(.send)
    }
}
