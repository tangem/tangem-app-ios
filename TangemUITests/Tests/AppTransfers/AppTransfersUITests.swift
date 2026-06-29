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

    // [REDACTED_TODO_COMMENT]
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

    func testFullTransferReachesTransferInProgressScreen() {
        setAllureId(9841)

        openSwapInTransferModeWithHotWallet()
            .enterFromAmount(Constants.amount)
            .waitForFeeCalculation()
            .waitForProviderBlockNotDisplayed()
            .confirmTransferAndOpenFinish()
            .assertHeaderTitle(Constants.transferInProgressTitle)
    }

    func testReceiveListAllowsIdenticalTokenOnAnotherAccount() {
        setAllureId(9989)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: Constants.ethereumTransferScenarios
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainSwap()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .chooseSourceToken(Constants.token)
            .tapToTokenSelector()
            .waitSwapTokenSelectorDisplayed()
            .waitForTokenAvailable(Constants.token)
    }

    func testFeeCalculationErrorDisablesTransfer() {
        setAllureId(9998)

        openSwapInTransferMode(
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameToken"),
                ScenarioConfig(name: "eth_call_api", initialState: "Started"),
                ScenarioConfig(name: "eth_network_balance", initialState: "Started"),
                ScenarioConfig(name: "eth_fee_history", initialState: "Unreachable"),
                ScenarioConfig(name: "eth_estimate_gas", initialState: "Unreachable"),
            ]
        )
        .enterFromAmount(Constants.amount)
        .waitForNotificationShown()
        .waitForConfirmButtonDisabled()
    }

    func testBroadcastErrorShowsAlertWithoutFinishScreen() {
        setAllureId(9999)

        openSwapInTransferModeWithHotWallet(
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameToken"),
                ScenarioConfig(name: "eth_call_api", initialState: "Started"),
                ScenarioConfig(name: "eth_network_balance", initialState: "Started"),
                ScenarioConfig(name: "eth_sendRawTransaction", initialState: "BroadcastError"),
            ]
        )
        .enterFromAmount(Constants.amount)
        .waitForFeeCalculation()
        .waitForProviderBlockNotDisplayed()
        .confirmSwap()
        .waitForSendErrorAlert()
    }

    func testModeSwitchesReactivelyWithoutScreenReload() {
        setAllureId(9994)

        let swapScreen = openSwapInTransferMode(
            token: Constants.solanaToken,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameSolanaWithUsdc"),
                ScenarioConfig(name: "solana_balance", initialState: "Started"),
                ScenarioConfig(name: "express_api_assets", initialState: "Started"),
                ScenarioConfig(name: "solana_from_pairs", initialState: "DexProvider"),
            ]
        )
        .assertConfirmButtonLabelIsTransfer()
        .waitForProviderBlockNotDisplayed()

        swapScreen
            .chooseReceiveToken(Constants.swapReceiveToken)
            .assertConfirmButtonLabelIsSwap()

        swapScreen
            .selectIdenticalReceiveToken(Constants.solanaToken)
            .assertConfirmButtonLabelIsTransfer()
            .waitForProviderBlockNotDisplayed()
    }

    func testMemoFieldIsNotEnteredManuallyInTransferMode() {
        setAllureId(10001)

        openSwapInTransferMode(
            token: Constants.xrpToken,
            scenarios: Constants.xrpTransferScenarios
        )
        .enterFromAmount(Constants.amount)
        .waitForFeeCalculation()
        .assertConfirmButtonLabelIsTransfer()
        .waitForMemoFieldNotDisplayed()
    }

    func testXrpNetworkFee() {
        setAllureId(10009)

        openSwapInTransferMode(
            token: Constants.xrpToken,
            scenarios: Constants.xrpTransferScenarios
        )
        .enterFromAmount(Constants.amount)
        .waitForFeeCalculation()
        .assertConfirmButtonLabelIsTransfer()
        .waitForProviderBlockNotDisplayed()
        .waitForFeeAmountDisplayed()
    }

    func testStellarNetworkFee() {
        setAllureId(10011)

        openSwapInTransferMode(
            token: Constants.stellarToken,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameXLM"),
            ]
        )
        .enterFromAmount(Constants.amount)
        .waitForFeeCalculation()
        .assertConfirmButtonLabelIsTransfer()
        .waitForProviderBlockNotDisplayed()
        .waitForFeeAmountDisplayed()
    }

    func testAmountBelowDestinationReserveDisablesTransfer() {
        setAllureId(9852)

        openSwapInTransferMode(
            token: Constants.solanaToken,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameSolana"),
                ScenarioConfig(name: "solana_balance", initialState: "Started"),
                ScenarioConfig(name: "solana_recipient_account", initialState: "NotExist"),
            ]
        )
        .enterFromAmount(Constants.belowDestinationReserveAmount)
        .waitForNotificationShown()
        .waitForConfirmButtonDisabled()
    }

    func testAmountBelowMinimumDisablesTransfer() {
        setAllureId(9997)

        openSwapInTransferMode(
            token: Constants.kaspaToken,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameKaspa"),
                ScenarioConfig(name: "kaspa_utxo", initialState: "more_than_84"),
            ]
        )
        .enterFromAmount(Constants.belowMinimumAmount)
        .waitForNotificationShown(title: Constants.invalidAmountTitle)
        .waitForNotificationMessageContaining(Constants.minimumAmountMessagePrefix)
        .waitForConfirmButtonDisabled()
    }

    private func openSwapInTransferMode(
        token: String = Constants.token,
        scenarios: [ScenarioConfig]? = nil
    ) -> SwapScreen {
        let resolvedScenarios = scenarios ?? Constants.ethereumTransferScenarios

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

    /// A hot wallet is required for flows that broadcast: the scanned mock card cannot sign in UI tests.
    private func openSwapInTransferModeWithHotWallet(
        token: String = Constants.token,
        scenarios: [ScenarioConfig]? = nil
    ) -> SwapScreen {
        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: scenarios ?? Constants.ethereumTransferScenarios
        )

        return importHotWallet()
            .generateMissingAddressesIfNeeded()
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
        static let xrpToken = "XRP Ledger"
        static let stellarToken = "Stellar"
        static let kaspaToken = "Kaspa"
        static let swapReceiveToken = "USDC"
        static let amount = "0.001"
        static let aboveBalanceAmount = "100"
        static let belowMinimumAmount = "0.00000001"
        static let belowDestinationReserveAmount = "0.0001"
        static let transferInProgressTitle = "Transfer in progress"
        static let invalidAmountTitle = "Invalid amount"
        static let minimumAmountMessagePrefix = "The minimum swapping amount is"

        static let ethereumTransferScenarios: [ScenarioConfig] = [
            ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameToken"),
            ScenarioConfig(name: "eth_call_api", initialState: "Started"),
            ScenarioConfig(name: "eth_network_balance", initialState: "Started"),
        ]

        static let xrpTransferScenarios: [ScenarioConfig] = [
            ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameXRP"),
            ScenarioConfig(name: "ripple_account_info", initialState: "Started"),
        ]
    }
}
