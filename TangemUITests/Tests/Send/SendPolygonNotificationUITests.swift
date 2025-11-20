//
//  SendPolygonNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class SendPolygonNotificationUITests: BaseTestCase {
    func testInsufficientEthereumNotificationDisplayed_WhenEthNetworkBalanceIsEmpty() {
        setAllureId(3645)

        let token = "POL (ex-MATIC)"
        let insufficientEthereumNotificationTitle = "Insufficient Ethereum to cover network fee"
        let goToETHButtonText = "Go to ETH"

        let ethNetworkBalanceScenario = ScenarioConfig(
            name: "eth_network_balance",
            initialState: "Empty"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [ethNetworkBalanceScenario]
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .waitForNotEnoughFeeForTransactionBanner()
            .waitForNotEnoughFeeNotificationContent(
                expectedTitle: insufficientEthereumNotificationTitle,
                expectedButtonText: goToETHButtonText
            )
    }
}
