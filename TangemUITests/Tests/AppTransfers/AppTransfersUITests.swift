//
//  AppTransfersUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class AppTransfersUITests: BaseTestCase {
    func testIdenticalPairSwitchesToTransferMode() {
        setAllureId(9838)

        openSwapInTransferMode()
            .enterFromAmount(Constants.amount)
            .waitForFeeCalculation()
            .assertConfirmButtonLabelIsTransfer()
            .waitForProviderBlockNotDisplayed()
            .waitForFeeAmountDisplayed()
    }

    func testZeroAmountKeepsTransferButtonDisabled() {
        setAllureId(9843)

        openSwapInTransferMode()
            .waitForProviderBlockNotDisplayed()
            .waitForConfirmButtonDisabled()
    }

    func testReversingTokensKeepsTransferMode() {
        setAllureId(9992)

        openSwapInTransferMode()
            .enterFromAmount(Constants.amount)
            .waitForFeeCalculation()
            .tapSwapTokensButton()
            .assertConfirmButtonLabelIsTransfer()
            .waitForProviderBlockNotDisplayed()
    }

    func testMaxAmountFractionSubtractsFee() {
        setAllureId(9847)

        openSwapInTransferMode()
            .tapMaxAmountFraction()
            .waitForFromAmountIsNotZero()
            .waitForFeeCalculation()
            .assertConfirmButtonLabelIsTransfer()
            .waitForConfirmButtonEnabled()
    }

    func testAmountAboveBalanceDisablesTransfer() {
        setAllureId(9844)

        openSwapInTransferMode()
            .enterFromAmount(Constants.aboveBalanceAmount)
            .waitForNotificationShown()
            .waitForConfirmButtonDisabled()
    }

    func testEvmNetworkFeeSpeedOptions() {
        setAllureId(10003)

        openSwapInTransferMode()
            .enterFromAmount(Constants.amount)
            .waitForFeeCalculation()
            .assertConfirmButtonLabelIsTransfer()
            .tapFeeBlock()
            .waitForFeeSelectorToAppear()
            .selectFeeOption(.priority)
            .validateFeeChanged()
    }

    func testUtxoNetworkFee() {
        setAllureId(10002)

        openSwapInTransferMode(
            token: Constants.bitcoinToken,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameBitcoin"),
                ScenarioConfig(name: "bitcoin_utxo", initialState: "BalanceAnyAddress"),
            ]
        )
        .enterFromAmount(Constants.amount)
        .waitForFeeCalculation()
        .assertConfirmButtonLabelIsTransfer()
        .waitForProviderBlockNotDisplayed()
        .waitForFeeAmountDisplayed()
    }

    func testSolanaNetworkFee() {
        setAllureId(10004)

        openSwapInTransferMode(
            token: Constants.solanaToken,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameSolana"),
                ScenarioConfig(name: "solana_balance", initialState: "Started"),
            ]
        )
        .enterFromAmount(Constants.amount)
        .waitForFeeCalculation()
        .assertConfirmButtonLabelIsTransfer()
        .waitForProviderBlockNotDisplayed()
        .waitForFeeAmountDisplayed()
    }

    func testInsufficientNativeCoinForFeeDisablesTransfer() {
        setAllureId(9845)

        openSwapInTransferMode(
            token: Constants.usdtToken,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameUsdt"),
                ScenarioConfig(name: "eth_call_api", initialState: "Started"),
                ScenarioConfig(name: "eth_network_balance", initialState: "EmptyAnyId"),
            ]
        )
        .enterFromAmount(Constants.amount)
        .waitForNotificationShown()
        .waitForConfirmButtonDisabled()
    }

    func testSearchFiltersReceiveTokenList() {
        setAllureId(9990)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true
        )

        let tokenSelector = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.polygonToken)
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapToTokenSelector()
            .waitSwapTokenSelectorDisplayed()

        tokenSelector
            .typeSearchText("f")
            .waitForTokenNotDisplayed(Constants.token)
            .waitForTokenNotDisplayed(Constants.polygonReceiveName)

        tokenSelector
            .clearSearchText()
            .typeSearchText("pol")
            .waitForTokenDisplayed(Constants.polygonReceiveName)
            .waitForTokenNotDisplayed(Constants.token)
    }

    private func openSwapInTransferMode(
        token: String = Constants.token,
        scenarios: [ScenarioConfig]? = nil
    ) -> SwapScreen {
        let resolvedScenarios = scenarios ?? [
            ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameToken"),
            ScenarioConfig(name: "eth_call_api", initialState: "Started"),
            ScenarioConfig(name: "eth_network_balance", initialState: "Started"),
        ]

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: resolvedScenarios
        )

        return CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseSourceToken(token)
            .selectIdenticalReceiveToken(token)
    }
}

private extension AppTransfersUITests {
    enum Constants {
        static let token = "Ethereum"
        static let polygonToken = "Polygon"
        static let polygonReceiveName = "POL (ex-MATIC)"
        static let bitcoinToken = "Bitcoin"
        static let solanaToken = "Solana"
        static let usdtToken = "Tether"
        static let amount = "0.001"
        static let aboveBalanceAmount = "100"
    }
}
