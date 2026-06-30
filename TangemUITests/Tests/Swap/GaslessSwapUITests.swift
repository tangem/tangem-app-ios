//
//  GaslessSwapUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class GaslessSwapUITests: BaseTestCase {
    func testNetworkFeeSelectionForSwap() {
        setAllureId(5110)
        launchGaslessSwap()

        let swapScreen = openColdWalletSwap(receiveToken: Constants.receivePolygon, amount: Constants.inputAmount)

        swapScreen.assertNetworkFeeBlockDisplayed()

        swapScreen
            .openFeeSelector()
            .waitForNetworkFeeSheet()
            .openTokenSelector(fromCoinSymbol: Constants.nativeSymbol)
            .waitForChooseTokenSheet()
            .assertFeeTokenAvailable(symbol: Constants.tokenSymbol)
    }

    func testFeeSelectorBottomSheet() {
        setAllureId(5111)
        launchGaslessSwap()

        openColdWalletSwap(receiveToken: Constants.receiveEthereum, amount: Constants.inputAmount)
            .openFeeSelector()
            .waitForNetworkFeeSheet()
            .assertFeeTokenAvailable(symbol: Constants.nativeSymbol)
            .assertCoinOffersSpeedChoice()
            .openTokenSelector(fromCoinSymbol: Constants.nativeSymbol)
            .waitForChooseTokenSheet()
            .assertFeeTokenAvailable(symbol: Constants.tokenSymbol)
            .selectFeeToken(symbol: Constants.tokenSymbol)
            .assertOnlyMarketSpeedForStablecoin()
            .applyReturningToSwap()
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
    }

    func testStablecoinFeeShownWithFiat() {
        setAllureId(5112)
        launchGaslessSwap()

        openColdWalletSwap(receiveToken: Constants.receiveEthereum, amount: Constants.inputAmount)
            .switchFeeTokenAndApply(currentFeeToken: Constants.nativeSymbol, newFeeToken: Constants.tokenSymbol)
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
            .assertFeeAmountContainsFiat()
    }

    func testMaxAmountReservesFee() {
        setAllureId(5113)
        launchGaslessSwap()

        openColdWalletSwap(receiveToken: Constants.receiveEthereum, amount: Constants.maxAmount)
            .switchFeeTokenAndApply(currentFeeToken: Constants.nativeSymbol, newFeeToken: Constants.tokenSymbol)
            .assertNoInsufficientFundsError()
            .waitForConfirmButtonEnabled()
    }

    func testSwitchFeeTokenBetweenCoinAndStablecoin() {
        setAllureId(5114)
        launchGaslessSwap()

        openColdWalletSwap(receiveToken: Constants.receiveEthereum, amount: Constants.inputAmount)
            .switchFeeTokenAndApply(currentFeeToken: Constants.nativeSymbol, newFeeToken: Constants.tokenSymbol)
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
            .switchFeeTokenAndApply(currentFeeToken: Constants.tokenSymbol, newFeeToken: Constants.nativeSymbol)
            .assertFeeCurrencySymbol(Constants.nativeSymbol)
    }

    func testFeeSelectionOptions() {
        setAllureId(5115)
        launchGaslessSwap()

        openColdWalletSwap(receiveToken: Constants.receiveEthereum, amount: Constants.inputAmount)
            .openFeeSelector()
            .waitForNetworkFeeSheet()
            .openTokenSelector(fromCoinSymbol: Constants.nativeSymbol)
            .waitForChooseTokenSheet()
            .assertFeeTokenAvailable(symbol: Constants.tokenSymbol)
            .selectFeeToken(symbol: Constants.tokenSymbol)
            .assertOnlyMarketSpeedForStablecoin()
            .applyReturningToSwap()
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
    }

    func testSignSwapWithStablecoinFee() {
        setAllureId(5116)
        launchGaslessSwap(
            tokensState: Constants.hotWalletTokensState,
            extraScenarios: [ScenarioConfig(name: Constants.exchangeStatusScenario, initialState: Constants.changellyState)]
        )

        openHotWalletSwap(receiveToken: Constants.receivePolygon, amount: Constants.inputAmount)
            .switchFeeTokenAndApply(currentFeeToken: Constants.nativeSymbol, newFeeToken: Constants.tokenSymbol)
            .assertFeeCurrencySymbol(Constants.tokenSymbol)
            .confirmSwap()

        SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()
            .waitForPendingExpressTransaction()
    }

    func testBestRateUnchangedWithStablecoinFee() {
        setAllureId(5117)
        launchGaslessSwap()

        let swapScreen = openColdWalletSwap(receiveToken: Constants.receiveEthereum, amount: Constants.inputAmount)

        swapScreen.assertBestRateDisplayed()
        let capturedReceiveAmount = swapScreen.captureReceiveAmount()

        swapScreen
            .switchFeeTokenAndApply(currentFeeToken: Constants.nativeSymbol, newFeeToken: Constants.tokenSymbol)
            .assertReceiveAmount(equals: capturedReceiveAmount)
    }

    func testInsufficientBalanceForFee() {
        setAllureId(5118)
        launchGaslessSwap(extraScenarios: [
            ScenarioConfig(name: Constants.usdcBalanceScenario, initialState: Constants.lowBalanceState),
        ])

        openColdWalletSwap(receiveToken: Constants.receiveEthereum, amount: Constants.lowAmount)
            .openFeeSelector()
            .waitForNetworkFeeSheet()
            .selectStablecoinAsFeeToken(coinSymbol: Constants.nativeSymbol, tokenSymbol: Constants.tokenSymbol)
            .assertNotEnoughFundsError()
            .assertApplyDisabled()
    }

    private func launchGaslessSwap(
        tokensState: String = Constants.polygonUSDCEthereumState,
        extraScenarios: [ScenarioConfig] = []
    ) {
        let scenarios = [
            ScenarioConfig(name: Constants.userTokensScenario, initialState: tokensState),
            ScenarioConfig(name: Constants.quotesScenario, initialState: Constants.polygonUSDCState),
            ScenarioConfig(name: Constants.assetsScenario, initialState: Constants.bitcoinExchangeEnabledState),
        ] + extraScenarios

        launchApp(tangemApiType: .mock, expressApiType: .mock, clearStorage: true, scenarios: scenarios)
    }

    @discardableResult
    private func openColdWalletSwap(receiveToken: String, amount: String) -> SwapScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.tokenName)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken(receiveToken)
            .enterFromAmount(amount)
    }

    @discardableResult
    private func openHotWalletSwap(receiveToken: String, amount: String) -> SwapScreen {
        importHotWallet()
            .tapToken(Constants.tokenName)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseReceiveToken(receiveToken)
            .enterFromAmount(amount)
    }

    private enum Constants {
        static let tokenName = "USDC"
        static let tokenSymbol = "USDC"
        static let nativeSymbol = "POL"
        static let receiveEthereum = "Ethereum"
        static let receivePolygon = "Polygon"
        static let inputAmount = "50"
        static let maxAmount = "100"
        static let lowAmount = "0.0005"

        static let userTokensScenario = "user_tokens_api"
        static let polygonUSDCEthereumState = "PolygonUSDCEthereum"
        static let hotWalletTokensState = "PolygonUSDCHotWallet"
        static let quotesScenario = "quotes_api"
        static let polygonUSDCState = "PolygonUSDC"
        static let assetsScenario = "express_api_assets"
        static let bitcoinExchangeEnabledState = "BitcoinExchangeEnabled"
        static let exchangeStatusScenario = "exchange_status_provider"
        static let changellyState = "Changelly"
        static let usdcBalanceScenario = "polygon_usdc_balance"
        static let lowBalanceState = "LowBalance"
    }
}
