//
//  GaslessSendViaSwapUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class GaslessSendViaSwapUITests: BaseTestCase {
    func testFeeTokenSelectionForSwap() {
        setAllureId(5120)
        launchSwap()

        importHotWalletAndOpenSwapSummary()
            .tapFeeBlock()
            .waitForNetworkFeeSheet()
            .openTokenSelector(fromCoinSymbol: Constants.nativeSymbol)
            .waitForChooseTokenSheet()
            .assertFeeTokenAvailable(symbol: Constants.tokenSymbol)
            .selectFeeToken(symbol: Constants.tokenSymbol)
            .tapApply()
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
    }

    func testInsufficientStablecoinBalanceBlocksSwap() {
        setAllureId(5121)
        launchSwap(extraScenarios: [
            ScenarioConfig(name: Constants.usdcBalanceScenario, initialState: Constants.lowBalanceState),
        ])

        importHotWalletAndOpenSwapSummary()
            .tapFeeBlock()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .assertNotEnoughFundsError()
            .assertApplyDisabled()
    }

    func testSignAndSendSwapPayingFeeWithStablecoin() {
        setAllureId(5122)
        launchSwap(extraScenarios: [
            ScenarioConfig(name: Constants.exchangeStatusScenario, initialState: Constants.changellyState),
        ])

        importHotWalletAndOpenSwapSummary()
            .tapFeeBlock()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .tapApply()
            .assertPrimaryAmountDisplayed()
            .assertRecipientAddress(Constants.recipientAddress)
            .assertReceiveAmountDisplayed()
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
            .tapSendButton()
            .waitForDisplay()
            .tapCloseButton()
            .waitForPendingExpressTransaction()
    }

    private func launchSwap(extraScenarios: [ScenarioConfig] = []) {
        let scenarios = [
            ScenarioConfig(name: Constants.userTokensScenario, initialState: Constants.hotWalletTokensState),
            ScenarioConfig(name: Constants.quotesScenario, initialState: Constants.polygonUSDCState),
            ScenarioConfig(name: Constants.assetsScenario, initialState: Constants.bitcoinExchangeEnabledState),
            ScenarioConfig(name: Constants.providersScenario, initialState: Constants.hotWalletSvSState),
        ] + extraScenarios

        launchApp(tangemApiType: .mock, expressApiType: .mock, clearStorage: true, scenarios: scenarios)
    }

    private func importHotWalletAndOpenSwapSummary() -> SendSummaryScreen {
        let sendScreen = CreateWalletSelectorScreen(app)
            .skipStories()
            .startWithMobileWallet()
            .tapImportButton()
            .enterSeedPhrase(TestSeedPhrases.hotWallet)
            .tapImportButton()
            .tapContinue()
            .skipAccessCode()
            .tapFinish()
            .tapToken(Constants.tokenName)
            .waitForActionButtons()
            .tapSendButton()
            .waitForDisplay()
            .waitForConvertButton()
            .tapConvertButton()

        sendScreen
            .enterTokenSearch(Constants.receiveTokenName)
            .waitForReceiveToken(name: Constants.receiveTokenName)
            .tapReceiveToken(name: Constants.receiveTokenName)
            .tapReceiveNetworkOption(name: Constants.receiveNetworkName)

        return sendScreen
            .enterReceiveAmount(Constants.amount)
            .tapNextButton()
            .enterDestination(Constants.recipientAddress)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
    }

    private enum Constants {
        static let tokenName = "USDC"
        static let tokenSymbol = "USDC"
        static let nativeSymbol = "POL"
        static let receiveTokenName = "Bitcoin"
        static let receiveNetworkName = "Bitcoin"
        static let amount = "1"
        static let recipientAddress = "bc1qt90qc0na7z05nh63kyd78tujfc8vqv6sl7e4a9"

        static let userTokensScenario = "user_tokens_api"
        static let hotWalletTokensState = "PolygonUSDCHotWallet"
        static let quotesScenario = "quotes_api"
        static let polygonUSDCState = "PolygonUSDC"
        static let assetsScenario = "express_api_assets"
        static let bitcoinExchangeEnabledState = "BitcoinExchangeEnabled"
        static let providersScenario = "networks_providers"
        static let hotWalletSvSState = "HotWalletSvS"

        static let usdcBalanceScenario = "polygon_usdc_balance"
        static let lowBalanceState = "LowBalance"
        static let exchangeStatusScenario = "exchange_status_provider"
        static let changellyState = "Changelly"
    }
}
