//
//  GaslessSendUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class GaslessSendUITests: BaseTestCase {
    func testMaxAmountReservesStablecoinFee() {
        setAllureId(5069)
        launchGaslessHotWallet()

        importHotWallet()
            .tapToken(Constants.tokenName)
            .waitForActionButtons(requireSwapEnabled: false)
            .tapSendButton()
            .waitForDisplay()
            .tapMaxButton()
            .tapNextButton()
            .enterDestination(Constants.recipientAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .tapFeeBlock()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .tapApply()
            .assertFeeCoverageWarningDisplayed()
            .assertSendButtonEnabled()
            .tapSendButton()
            .waitForDisplay()
    }

    func testSignAndSendGaslessTransaction() {
        setAllureId(5065)
        launchGaslessHotWallet()

        importHotWallet()
            .tapToken(Constants.tokenName)
            .waitForActionButtons(requireSwapEnabled: false)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(Constants.amount)
            .tapNextButton()
            .enterDestination(Constants.recipientAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .tapFeeBlock()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .tapApply()
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
            .assertSendButtonEnabled()
            .tapSendButton()
            .waitForDisplay()
    }

    func testGaslessTransactionInHistory() {
        setAllureId(5066)

        let scenarios = [
            ScenarioConfig(name: Constants.userTokensScenario, initialState: Constants.polygonUSDCState),
            ScenarioConfig(name: Constants.quotesScenario, initialState: Constants.polygonUSDCState),
        ]
        launchApp(tangemApiType: .mock, clearStorage: true, scenarios: scenarios)

        let gaslessFeeKey = Constants.gaslessFeeTxKey
        let sentKey = Constants.sentTxKey

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.tokenName)
            .waitForTransaction(key: gaslessFeeKey)
            .assertTransactionConfirmed(key: gaslessFeeKey)
            .waitForTransaction(key: sentKey)
            .assertTransactionAmount(key: sentKey, contains: Constants.sentAmount)
            .assertTransactionCurrency(key: sentKey, equals: Constants.tokenSymbol)
            .assertTransactionAmount(key: gaslessFeeKey, contains: Constants.gaslessFeeAmount)
            .assertTransactionCurrency(key: gaslessFeeKey, equals: Constants.tokenSymbol)
    }

    private func launchGaslessHotWallet() {
        let scenarios = [
            ScenarioConfig(name: Constants.userTokensScenario, initialState: Constants.hotWalletTokensState),
            ScenarioConfig(name: Constants.quotesScenario, initialState: Constants.polygonUSDCState),
        ]
        launchApp(tangemApiType: .mock, clearStorage: true, scenarios: scenarios)
    }

    private enum Constants {
        static let amount = "1"
        static let sentAmount = "1.00"
        static let gaslessFeeAmount = "0.10"
        static let recipientAddress = "0x5aa711F440Eb6d4361148bBD89d03464628ace84"
        static let tokenName = "USDC"
        static let tokenSymbol = "USDC"
        static let nativeSymbol = "POL"

        static let gaslessFeeTxKey = "gaslessTransactionFee"
        static let sentTxKey = "transfer"

        static let userTokensScenario = "user_tokens_api"
        static let quotesScenario = "quotes_api"
        static let polygonUSDCState = "PolygonUSDC"
        static let hotWalletTokensState = "PolygonUSDCHotWallet"
    }
}
