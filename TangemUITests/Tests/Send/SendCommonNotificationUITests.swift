//
//  SendCommonNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendCommonNotificationUITests: BaseTestCase {
    private let ethTokenName = "Ethereum"
    private let destination = "0x24298f15b837E5851925E18439490859e0c1F1ee"

    func testNotificationDisplayed_WhenCustomFeeLowerThanSlow() {
        setAllureId(4293)

        prepareSendFlow()

        SendScreen(app)
            .enterAmount("0.01")
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButtonToSummary()
            .tapFeeBlock()
            .selectCustom()
            .setLowCustomFee()
            .tapFeeSelectorDone()
            .waitForCustomFeeTooLowBanner()
            .waitForSendButtonEnabled()
    }

    func testNotificationDisplayed_WhenTotalExceedsBalance() {
        setAllureId(4221)

        prepareSendFlow()

        SendScreen(app)
            .enterAmount("0.9999")
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButton()
            .waitForFeeWillBeSubtractFromSendingAmountBanner()
            .waitForSendButtonEnabled()
    }

    func testNotificationDisplayed_WhenCustomFeeIsHigh() {
        setAllureId(4294)

        prepareSendFlow()

        SendScreen(app)
            .enterAmount("0.01")
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButtonToSummary()
            .tapFeeBlock()
            .selectCustom()
            .setHighCustomFee()
            .tapFeeSelectorDone()
            .waitForCustomFeeTooHighBanner()
            .waitForSendButtonEnabled()
    }

    func testInsufficientEthereumFeeBannerNavigatesToEthereumToken() {
        setAllureId(3645)

        let polTokenName = "POL (ex-MATIC)"

        let ethNetworkScenario = ScenarioConfig(
            name: "eth_network_balance",
            initialState: "Empty"
        )

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [ethNetworkScenario]
        )

        let polTokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(polTokenName)
            .waitForNotEnoughFeeForTransactionBanner()

        polTokenScreen
            .tapGoToFeeCurrencyButton()
            .waitForTokenName(ethTokenName)
            .waitForActionButtons()
    }

    private func prepareSendFlow() {
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(ethTokenName)
            .tapSendButton()
            .waitForDisplay()
    }
}
