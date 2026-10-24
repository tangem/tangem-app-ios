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
            stakingApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "HotWalletSvS"),
                ScenarioConfig(name: "moralis_evm_token_balances_api", initialState: "PolStakingEthereum"),
                ScenarioConfig(name: "staking_eth_pol_balances", initialState: "Started"),
            ]
        )

        let summaryScreen = importHotWallet()
            .tapToken(token)
            .openStakeDetails()
            .validate()
            .validateValues()
            .proceedToSendScreen()
            .waitForDisplay()
            .assertMaxButtonEnabled()
            .enterStakingAmount(tokenValue)
            .goToSummary()
            .waitForDisplay()
            .waitForAmountValue(tokenValue)
            .assertFiatAmountDisplayed()

        let finishScreen = summaryScreen
            .tapSendButton()
            .waitForDisplay()

        wireMockClient.setScenarioStateSync("staking_eth_pol_balances", state: "Staked")

        finishScreen
            .closeToStakingDetails()
            .goBack()
            .waitForStakingInfo()
    }

    func test_StakedToken_ShowStakingInfo() {
        setAllureId(3558)

        let stakedScenario = ScenarioConfig(
            name: "staking_eth_pol_balances",
            initialState: "Staked"
        )

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            scenarios: [stakedScenario]
        )

        let tokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .waitForStakingInfo()

        let fiatBalanceBeforeToggle = tokenScreen.getStakingBalance()
        XCTAssertTrue(fiatBalanceBeforeToggle.contains("$"), "Staking balance should show a fiat value but was '\(fiatBalanceBeforeToggle)'")

        let cryptoBalanceBeforeToggle = tokenScreen.getStakingBalanceCrypto()
        XCTAssertTrue(cryptoBalanceBeforeToggle.contains("POL"), "Staking balance should show the staked POL amount but was '\(cryptoBalanceBeforeToggle)'")

        let totalBalance = tokenScreen.getTotalBalance()
        tokenScreen.tapAvailableSegment()
        let availableBalance = tokenScreen.getAvailableBalance()
        XCTAssertNotEqual(totalBalance, availableBalance, "Available balance should differ from total balance once staked funds are excluded")

        XCTAssertEqual(
            fiatBalanceBeforeToggle,
            tokenScreen.getStakingBalance(),
            "Staked fiat amount should not change when switching between Total and Available"
        )
        XCTAssertEqual(
            cryptoBalanceBeforeToggle,
            tokenScreen.getStakingBalanceCrypto(),
            "Staked crypto amount should not change when switching between Total and Available"
        )
    }

    func testStakingMoreScreens_FromStakedToken() {
        setAllureId(3550)

        let tokenValue = "1"

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "HotWalletSvS"),
                ScenarioConfig(name: "moralis_evm_token_balances_api", initialState: "PolStakingEthereum"),
                ScenarioConfig(name: "staking_eth_pol_balances", initialState: "Staked"),
            ]
        )

        let summaryScreen = importHotWallet()
            .tapToken(token)
            .tapNativeStakingBlock()
            .validate()
            .validateValues()
            .assertYourStakesTitle()
            .assertActiveStakeDisplayed()
            .assertStakeButtonLabel("Stake more")
            .proceedToSendScreen()
            .waitForDisplay()
            .enterStakingAmount(tokenValue)
            .goToSummary()
            .waitForDisplay()
            .waitForAmountValue(tokenValue)

        let updatedSummaryScreen = summaryScreen
            .tapValidatorBlock()
            .waitForDisplay()
            .selectTarget(name: "Everstake")
            .tapContinue()
            .assertValidatorName("Everstake")

        let finishScreen = updatedSummaryScreen
            .tapSendButton()
            .waitForDisplay()

        wireMockClient.setScenarioStateSync("staking_eth_pol_balances", state: "StakedTwoValidators")

        finishScreen
            .closeToStakingDetails()
            .assertActiveStakeCount(2)
    }
}
