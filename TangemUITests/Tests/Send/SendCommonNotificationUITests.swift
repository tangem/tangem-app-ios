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

    func testNotificationDisplayed_WhenCustomFeeLowerThanSlow() throws {
        setAllureId(4293)

        try skipDueToBug("[REDACTED_INFO]", description: "Send: It is not possible to paste an amount into the input field")

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

    func testNotificationDisplayed_WhenCustomFeeIsHigh() throws {
        setAllureId(4294)

        try skipDueToBug("[REDACTED_INFO]", description: "Send: It is not possible to paste an amount into the input field")

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

    func testInsufficientSolanaFeeBannerNavigatesToSolanaToken() {
        setAllureId(3645)

        let usdcSolanaToken = "USDC"
        let topUpTokenName = "Solana"

        let tokensScenario = ScenarioConfig(name: "user_tokens_api", initialState: "SolanaUSDC")
        let solanaBalanceScenario = ScenarioConfig(name: "solana_balance", initialState: "Empty")

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [tokensScenario, solanaBalanceScenario]
        )

        let usdcSolanaScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(usdcSolanaToken)
            .waitForNotEnoughFeeForTransactionBanner()

        usdcSolanaScreen
            .tapGoToFeeCurrencyButton()
            .waitForTokenName(topUpTokenName)
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
