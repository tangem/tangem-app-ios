//
//  GaslessFeeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class GaslessFeeUITests: BaseTestCase {
    func testNetworkFeeTokenSelectionAvailable() {
        setAllureId(5061)
        launchGasless()

        openSendSummary()
            .tapFeeBlock()
            .waitForNetworkFeeSheet()
            .openTokenSelector(fromCoinSymbol: Constants.nativeSymbol)
            .waitForChooseTokenSheet()
            .assertFeeTokenAvailable(symbol: Constants.tokenSymbol)
    }

    func testFeeCalculatedInStablecoin() {
        setAllureId(5062)
        launchGasless()

        openSendSummary()
            .tapFeeBlock()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .tapApply()
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
            .assertSendButtonEnabled()
    }

    func testOnlyMarketSpeedAvailableForStablecoinFee() {
        setAllureId(5064)
        launchGasless()

        openSendSummary()
            .tapFeeBlock()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .assertOnlyMarketSpeedForStablecoin()
    }

    func testSwitchFeeTokenBackToCoin() {
        setAllureId(5068)
        launchGasless()

        openSendSummary()
            .tapFeeBlock()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .openTokenSelector(fromCoinSymbol: Constants.tokenSymbol)
            .waitForChooseTokenSheet()
            .selectFeeToken(symbol: Constants.nativeSymbol)
            .tapApply()
            .assertFeeCurrencySymbol(Constants.nativeSymbol)
            .assertFeeCoverageWarningNotDisplayed()
            .assertSendButtonEnabled()
    }

    func testInsufficientBalanceForFee() {
        setAllureId(5063)
        launchGasless(extraScenarios: [ScenarioConfig(name: Constants.usdcBalanceScenario, initialState: Constants.lowBalanceState)])

        openSendScreen()
            .tapMaxButton()
            .tapNextButton()
            .enterDestination(Constants.recipientAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .tapFeeBlock()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .assertNotEnoughFundsError()
            .assertApplyDisabled()
    }

    func testNoInsufficientCoinNotificationWhenGasless() {
        setAllureId(5097)
        launchGasless(extraScenarios: [ScenarioConfig(name: Constants.coinBalanceScenario, initialState: Constants.zeroBalanceState)])

        openSendSummary()
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
            .assertInsufficientCoinForFeeNotificationNotDisplayed()
            .assertSendButtonEnabled()
    }

    private func launchGasless(extraScenarios: [ScenarioConfig] = []) {
        let scenarios = [
            ScenarioConfig(name: Constants.userTokensScenario, initialState: Constants.polygonUSDCState),
            ScenarioConfig(name: Constants.quotesScenario, initialState: Constants.polygonUSDCState),
        ] + extraScenarios

        launchApp(tangemApiType: .mock, clearStorage: true, scenarios: scenarios)
    }

    private func openSendScreen() -> SendScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.tokenName)
            .waitForActionButtons(requireSwapEnabled: false)
            .tapSendButton()
            .waitForDisplay()
    }

    private func openSendSummary() -> SendSummaryScreen {
        openSendScreen()
            .enterAmount(Constants.amount)
            .tapNextButton()
            .enterDestination(Constants.recipientAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
    }

    private enum Constants {
        static let amount = "1"
        static let recipientAddress = "0x5aa711F440Eb6d4361148bBD89d03464628ace84"
        static let tokenName = "USDC"
        static let tokenSymbol = "USDC"
        static let nativeSymbol = "POL"

        static let userTokensScenario = "user_tokens_api"
        static let quotesScenario = "quotes_api"
        static let polygonUSDCState = "PolygonUSDC"

        static let usdcBalanceScenario = "polygon_usdc_balance"
        static let lowBalanceState = "LowBalance"
        static let coinBalanceScenario = "polygon_coin_balance"
        static let zeroBalanceState = "ZeroBalance"
    }
}
