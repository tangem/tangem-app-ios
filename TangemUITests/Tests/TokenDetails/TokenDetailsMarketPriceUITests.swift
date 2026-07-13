//
//  TokenDetailsMarketPriceUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TokenDetailsMarketPriceUITests: BaseTestCase {
    func testTokenDetailsMarketPriceBlockData() {
        setAllureId(301)

        let token = "Dogecoin"

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: token),
                ScenarioConfig(name: "quotes_api", initialState: token),
            ]
        )

        let tokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)

        // Markets data drives the block; refresh forces it in on slow CI.
        pullToRefresh()

        tokenScreen
            .marketPriceBlock()
            .waitForBlock()
            .validateBlockData()
    }
}
