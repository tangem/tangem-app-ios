//
//  BlockchainSmokeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class BlockchainSmokeUITests: BaseTestCase {
    func testScanWallet2Card_SelectXRPToken_CheckTopUpWalletBannerBehavior() {
        setAllureId(990)

        let xrpScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "XRP"
        )

        let notFoundAccountInfo = ScenarioConfig(
            name: "ripple_account_info",
            initialState: "AccountNotFound"
        )

        let notFoundLines = ScenarioConfig(
            name: "ripple_account_lines",
            initialState: "AccountNotFound"
        )

        let foundAccountInfo = ScenarioConfig(
            name: "ripple_account_info",
            initialState: "Started"
        )

        let foundAccountLines = ScenarioConfig(
            name: "ripple_account_lines",
            initialState: "Started"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [
                xrpScenario,
                notFoundAccountInfo,
                notFoundLines,
            ]
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken("XRP Ledger")
            .validateTopUpWalletBannerExists()

        setupWireMockScenarios([foundAccountInfo, foundAccountLines])

        pullToRefresh()

        TokenScreen(app)
            .validateTopUpWalletBannerNotExists()
    }
}
