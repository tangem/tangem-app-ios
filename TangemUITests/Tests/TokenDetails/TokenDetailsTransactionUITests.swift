//
//  TokenDetailsTransactionUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TokenDetailsTransactionUITests: BaseTestCase {
    private let token = "Dogecoin"
    private let currencySymbol = "DOGE"
    private let transactionKey = "transfer"
    private let recipientAddressPrefix = "DJQR"

    func testTokenDetailsActiveOutgoingTransactionBlock() {
        setAllureId(304)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: token),
                ScenarioConfig(name: "quotes_api", initialState: token),
                ScenarioConfig(name: "dogecoin_tx_history", initialState: "UnconfirmedOutgoing"),
            ]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .waitForTransaction(key: transactionKey)
            .assertTransactionInProgress(key: transactionKey)
            .assertTransactionCurrency(key: transactionKey, equals: currencySymbol)
            .assertTransactionSubtitle(key: transactionKey, contains: recipientAddressPrefix)
    }

    func testTokenDetailsSendUnavailableForZeroBalanceWithActiveTransaction() {
        setAllureId(10209)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: token),
                ScenarioConfig(name: "quotes_api", initialState: token),
                ScenarioConfig(name: "dogecoin_tx_history", initialState: "ZeroBalanceUnconfirmedOutgoing"),
                ScenarioConfig(name: "dogecoin_utxo", initialState: "Empty"),
            ]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .waitForTransaction(key: transactionKey)
            .assertTransactionInProgress(key: transactionKey)
            .verifySendUnavailable()
    }
}
