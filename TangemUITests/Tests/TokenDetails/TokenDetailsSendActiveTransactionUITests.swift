//
//  TokenDetailsSendActiveTransactionUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TokenDetailsSendActiveTransactionUITests: BaseTestCase {
    private let token = "Dogecoin"
    private let utxoScenario = "dogecoin_utxo"

    func testSendBlockedWhileTransactionActiveThenAvailableAfterCompletion() {
        setAllureId(4465)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: token),
                ScenarioConfig(name: utxoScenario, initialState: "IncomingPending"),
            ]
        )

        let tokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)

        let backToTokenScreen = tokenScreen
            .tapTransferButton()
            .tapSendButton()
            .verifyPendingTransactionSendUnavailableAlert(network: token)
            .dismissPendingTransactionAlert()

        setupWireMockScenarios([ScenarioConfig(name: utxoScenario, initialState: "Started")])
        pullToRefresh()

        backToTokenScreen
            .tapTransferButton()
            .tapSendButton()
            .waitForDisplay()
    }
}
