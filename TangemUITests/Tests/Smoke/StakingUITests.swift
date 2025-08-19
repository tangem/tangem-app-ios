//
//  StakingUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StakingUITests: BaseTestCase {
    let token = "POL (ex-MATIC)"

    func testStakingDetailsScreen_OpensWhenTappingStakeButton() {
        setAllureId(3548)

        let tokenValue = "1"

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .openStakeDetails()
            .validate()
            .validateValues()
            .proceedToSendScreen()
            .validate()
            .enterStakingAmount(tokenValue)
            .gotToSummary()
            .validate()
            .validateAmountValue(tokenValue)
            .validate()
    }

    func test_StakedToken_ShowStakingInfo() {
        setAllureId(3558)

        let stakedScenario = ScenarioConfig(
            name: "staking_eth_pol",
            initialState: "Staked"
        )

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            scenarios: [stakedScenario]
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .validateStakingInfo()
    }
}
