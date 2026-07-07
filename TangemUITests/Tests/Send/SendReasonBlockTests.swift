//
//  SendReasonBlockTests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SendReasonBlockTests: BaseTestCase {
    func testReasonBlockSendUnavailableWithPendingTransaction() {
        setAllureId(3616)

        let walletScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Dogecoin"
        )
        let dogecoinUtxoScenario = ScenarioConfig(
            name: "dogecoin_utxo",
            initialState: "IncomingPending"
        )
        let token = "Dogecoin"

        launchApp(
            tangemApiType: .mock,
            scenarios: [
                walletScenario,
                dogecoinUtxoScenario,
            ]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapTransferButton()
            .tapSendButton()
            .verifyPendingTransactionSendUnavailableAlert(network: token)
    }

    func testReasonBlockTokenWithdrawalUnavailableWithoutFeeCoverage() {
        setAllureId(3615)

        let walletScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "SolanaUSDC"
        )
        let solBalanceScenario = ScenarioConfig(
            name: "solana_balance",
            initialState: "Empty"
        )
        let token = "USDC"
        let feeCurrencyName = "Solana"
        let feeCurrencySymbol = "SOL"

        launchApp(
            tangemApiType: .mock,
            scenarios: [
                walletScenario,
                solBalanceScenario,
            ]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet)
            .tapToken(token)
            .verifyInsufficientFeeCurrencyNotification(token: token, feeCurrencyName: feeCurrencyName, feeCurrencySymbol: feeCurrencySymbol)
            .tapGoToFeeCurrencyButton()
            .waitForTokenName(feeCurrencyName)
    }
}
