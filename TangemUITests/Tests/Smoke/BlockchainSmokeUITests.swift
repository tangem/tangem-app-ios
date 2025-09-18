//
//  BlockchainSmokeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class BlockchainSmokeUITests: BaseTestCase {
    func testSendCardanoWithInvalidAmount_ShowsInvalidAmountBanner() {
        let network = "Cardano"
        let cardanoScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: network
        )
        let destinationAddress = "addr1q8tl5q2al97clkvht3x5wa0fsxtsn60h69qv3z9qzjk97acl8vc4df3r6c4xz9a4lj9388fkazw4na6t7yx8x6mvw32qsmvtwy"

        launchApp(
            tangemApiType: .mock,
            scenarios: [cardanoScenario]
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(network)
            .tapActionButton(.send)

        SendScreen(app)
            .enterAmount("0,4")
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .waitForInvalidAmountBanner()
    }
}
