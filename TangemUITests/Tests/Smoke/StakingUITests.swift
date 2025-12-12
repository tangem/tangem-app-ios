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

        let stakeScenario = ScenarioConfig(
            name: "staking_eth_pol_balances_ios",
            initialState: "Started"
        )

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            scenarios: [stakeScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .openStakeDetails()
            .validate()
            .validateValues()
            .proceedToSendScreen()
            .waitForDisplay()
            .enterStakingAmount(tokenValue)
            .goToSummary()
            .waitForDisplay()
            .waitForAmountValue(tokenValue)
    }

    func test_StakedToken_ShowStakingInfo() {
        setAllureId(3558)

        let stakedScenario = ScenarioConfig(
            name: "staking_eth_pol_balances_ios",
            initialState: "Staked"
        )

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            scenarios: [stakedScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .waitForStakingInfo()
    }
}
