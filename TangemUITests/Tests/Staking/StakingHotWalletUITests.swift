//
//  StakingHotWalletUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StakingHotWalletUITests: BaseTestCase {
    func testWithdrawStaking() {
        setAllureId(2188)

        let tokenScreen = launchHotWalletPolStaking(stakingState: Constants.withdrawable)

        let stakingDetails = tokenScreen
            .waitForStakingInfo()
            .tapNativeStakingBlock()
            .assertYourStakesTitle()
            .assertWithdrawEntryDisplayed()

        let finish = stakingDetails
            .tapWithdrawEntry()
            .waitForStakingConfirm()
            .tapSendButton()

        wireMockClient.setScenarioStateSync(Constants.stakingScenario, state: Constants.started)

        finish
            .waitForDisplay()
            .assertAmountDisplayed()
            .closeToStakingDetails()
            .assertWithdrawEntryNotDisplayed()
    }

    func testClaimRewards() {
        setAllureId(2190)

        let tokenScreen = launchHotWalletPolStaking(stakingState: Constants.rewards)

        let finish = tokenScreen
            .waitForStakingInfo()
            .tapNativeStakingBlock()
            .validate()
            .tapRewardsBlock()
            .waitForStakingConfirm()
            .tapSendButton()

        wireMockClient.setScenarioStateSync(Constants.stakingScenario, state: Constants.staked)

        finish
            .waitForDisplay()
            .assertAmountDisplayed()
            .closeToStakingDetails()
            .assertNoRewardsToClaim()
    }

    func testUnstakeStaking() {
        setAllureId(2192)

        let tokenScreen = launchHotWalletPolStaking(stakingState: Constants.staked)

        let finish = tokenScreen
            .waitForStakingInfo()
            .tapNativeStakingBlock()
            .validate()
            .assertActiveStakeDisplayed()
            .tapActiveStake()
            .waitForDisplay()
            .tapMaxAmount()
            .goToSummary()
            .waitForStakingConfirm()
            .assertUnstakeNotificationDisplayed()
            .tapSendButton()

        wireMockClient.setScenarioStateSync(Constants.stakingScenario, state: Constants.unstaking)

        finish
            .waitForDisplay()
            .assertAmountDisplayed()
            .closeToStakingDetails()
            .assertYourStakesTitle()
            .assertUnstakingEntryDisplayed()
    }

    func testEnterStakingAndValidateResult() {
        setAllureId(2193)

        let tokenScreen = launchHotWalletPolStaking(stakingState: Constants.started)

        let finish = tokenScreen
            .waitForStakingInfo()
            .tapNativeStakingBlock()
            .validate()
            .validateValues()
            .proceedToSendScreen()
            .waitForDisplay()
            .enterStakingAmount(Constants.stakeAmount)
            .goToSummary()
            .waitForDisplay()
            .waitForAmountValue(Constants.stakeAmount)
            .tapSendButton()

        wireMockClient.setScenarioStateSync(Constants.stakingScenario, state: Constants.staked)

        let main = finish
            .waitForDisplay()
            .assertAmountDisplayed()
            .closeToStakingDetails()
            .assertYourStakesTitle()
            .assertActiveStakeDisplayed()
            .assertNoRewardsToClaim()
            .tapBackButton(to: TokenScreen.self)
            .goBackToMain()

        main.waitForTotalBalanceContainsCurrency(Constants.totalBalance)
    }

    private func launchHotWalletPolStaking(stakingState: String) -> TokenScreen {
        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: Constants.portfolioScenario, initialState: Constants.hotWalletPortfolio),
                ScenarioConfig(name: Constants.balancesScenario, initialState: Constants.polStakingBalances),
                ScenarioConfig(name: Constants.stakingScenario, initialState: stakingState),
            ]
        )

        return importHotWallet().tapToken(Constants.polToken)
    }

    private enum Constants {
        static let polToken = "POL (ex-MATIC)"

        static let portfolioScenario = "user_tokens_api"
        static let hotWalletPortfolio = "HotWalletSvS"

        static let balancesScenario = "moralis_evm_token_balances_api"
        static let polStakingBalances = "PolStakingEthereum"

        static let stakingScenario = "staking_eth_pol_balances"
        static let started = "Started"
        static let staked = "Staked"
        static let withdrawable = "Withdrawable"
        static let rewards = "Rewards"
        static let unstaking = "Unstaking"

        static let stakeAmount = "1"
        static let totalBalance = "3,299.37"
    }
}
