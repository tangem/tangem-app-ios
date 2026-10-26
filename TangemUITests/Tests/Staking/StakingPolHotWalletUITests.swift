//
//  StakingPolHotWalletUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StakingPolHotWalletUITests: BaseTestCase {
    func testClaimRewardsOverOnePol() {
        setAllureId(3556)

        let tokenScreen = launchHotWalletPolStaking(stakingState: Constants.State.rewardsOverOne)
            .tapToken(Constants.polToken)
            .waitForNonZeroTotalBalance()

        let finish = tokenScreen
            .waitForStakingInfo()
            .tapNativeStakingBlock()
            .assertRewardsAmount(Constants.Amount.rewards)
            .tapRewardsBlock()
            .waitForStakingConfirm()
            .assertStakingActionConfirm(.claimRewards)
            .tapSendButton()

        wireMockClient.setScenarioStateSync(Constants.Scenario.staking, state: Constants.State.stakedLarge)

        finish
            .assertStakingSuccessContent()
            .closeToStakingDetails()
            .assertNoRewardsToClaim()
    }

    func testWithdrawUnstakedPol() {
        setAllureId(3553)

        let tokenScreen = launchHotWalletPolStaking(stakingState: Constants.State.withdrawable)
            .tapToken(Constants.polToken)
            .waitForNonZeroTotalBalance()

        let finish = tokenScreen
            .waitForStakingInfo()
            .tapNativeStakingBlock()
            .assertWithdrawEntryDisplayed()
            .assertWithdrawEntryReadyToWithdraw()
            .tapWithdrawEntry()
            .waitForStakingConfirm()
            .assertStakingActionConfirm(.withdraw)
            .tapSendButton()

        wireMockClient.setScenarioStateSync(Constants.Scenario.staking, state: Constants.State.started)

        finish
            .assertStakingSuccessContent()
            .closeToStakingDetails()
            .assertStakeAvailableWithoutPositions()
            .assertWithdrawEntryNotDisplayed()
    }

    func testFullUnstakePol() {
        setAllureId(3552)

        let main = launchHotWalletPolStaking(stakingState: Constants.State.stakedLarge, withPartialExitYield: true)

        let result = unstake(
            from: main,
            stakingStateAfterUnstake: Constants.State.unstakingLarge,
            enterAmount: { $0.tapMaxAmount() }
        )

        result.details
            .assertUnstakingAmount(Constants.Amount.staked)
            .assertNoActiveStake()

        assertBalancesUnchangedAndEthereumDecreased(result)
    }

    func testPartialUnstakePol() {
        setAllureId(3551)

        let main = launchHotWalletPolStaking(stakingState: Constants.State.stakedLarge, withPartialExitYield: true)

        let result = unstake(
            from: main,
            stakingStateAfterUnstake: Constants.State.partiallyUnstaking,
            enterAmount: { $0.replaceStakingAmount(Constants.Amount.unstakeInput) }
        )

        result.details
            .assertUnstakingAmount(Constants.Amount.unstaked)
            .assertActiveStakeAmount(Constants.Amount.remaining)

        assertBalancesUnchangedAndEthereumDecreased(result)
    }

    func testUnstakeAmountBetweenMinimumAndStakedPol() {
        setAllureId(11579)

        let main = launchHotWalletPolStaking(stakingState: Constants.State.stakedLarge, withPartialExitYield: true)

        unstake(
            from: main,
            stakingStateAfterUnstake: Constants.State.partiallyUnstaking,
            enterAmount: { $0.replaceStakingAmount(Constants.Amount.unstakeInput) }
        )
        .details
        .assertActiveStakeAmount(Constants.Amount.remaining)
    }

    private func launchHotWalletPolStaking(stakingState: String, withPartialExitYield: Bool = false) -> MainScreen {
        var scenarios = [
            ScenarioConfig(name: Constants.Scenario.portfolio, initialState: Constants.State.hotWalletPortfolio),
            ScenarioConfig(name: Constants.Scenario.balances, initialState: Constants.State.polStakingBalances),
            ScenarioConfig(name: Constants.Scenario.staking, initialState: stakingState),
        ]

        if withPartialExitYield {
            scenarios.append(ScenarioConfig(name: Constants.Scenario.yield, initialState: Constants.State.partialUnstake))
        }

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            clearStorage: true,
            scenarios: scenarios
        )

        return importHotWallet()
    }

    private func unstake(
        from main: MainScreen,
        stakingStateAfterUnstake: String,
        enterAmount: (StakingSendScreen) -> StakingSendScreen
    ) -> UnstakeResult {
        let ethereumBefore = main
            .waitForTokenBalanceLoaded(tokenName: Constants.ethereumToken)
            .getTokenBalanceNumeric(tokenName: Constants.ethereumToken)

        let tokenScreen = main
            .tapToken(Constants.polToken)
            .waitForNonZeroTotalBalance()
            .waitForStakingInfo()
            .assertStakingBalanceCrypto(contains: Constants.Amount.staked)

        let totalBefore = tokenScreen.getTotalBalance()
        let availableBefore = tokenScreen.tapAvailableSegment().getAvailableBalance()
        tokenScreen.tapTotalSegment()

        let amountScreen = tokenScreen
            .tapNativeStakingBlock()
            .assertActiveStakeAmount(Constants.Amount.staked)
            .tapActiveStake()
            .waitForDisplay()

        let finish = enterAmount(amountScreen)
            .goToSummary()
            .waitForStakingConfirm()
            .assertStakingActionConfirm(.unstake)
            .tapSendButton()

        wireMockClient.setScenarioStateSync(Constants.Scenario.staking, state: stakingStateAfterUnstake)
        wireMockClient.setScenarioStateSync(Constants.Scenario.ethereumBalance, state: Constants.State.afterUnstake)

        let details = finish
            .assertStakingSuccessContent()
            .closeToStakingDetails()
            .assertYourStakesTitle()
            .assertUnstakingEntryDisplayed()

        return UnstakeResult(
            details: details,
            totalBefore: totalBefore,
            availableBefore: availableBefore,
            ethereumBefore: ethereumBefore
        )
    }

    private func assertBalancesUnchangedAndEthereumDecreased(_ result: UnstakeResult) {
        let tokenScreen = result.details.goBack()

        refreshUntil(tokenScreen, "Total balance is unchanged") {
            tokenScreen.loadedTotalBalance == result.totalBefore
        }

        tokenScreen.tapAvailableSegment()

        refreshUntil(tokenScreen, "Available balance is unchanged") {
            tokenScreen.loadedAvailableBalance == result.availableBefore
        }

        let main = tokenScreen.goBackToMain()

        for _ in 0 ..< Constants.refreshAttempts {
            pullToRefresh()
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    guard let current = main.loadedTokenBalanceNumeric(tokenName: Constants.ethereumToken) else {
                        return false
                    }
                    return current < result.ethereumBefore
                },
                object: nil
            )
            if XCTWaiter().wait(for: [expectation], timeout: Constants.refreshSettleTimeout) == .completed {
                return
            }
        }
        XCTFail("Timed out waiting: Ethereum balance decreases from \(result.ethereumBefore)")
    }

    private func refreshUntil(_ screen: TokenScreen, _ description: String, _ condition: @escaping () -> Bool) {
        for _ in 0 ..< Constants.refreshAttempts {
            let requestsBefore = stakingBalancesRequestCount()
            screen.pullToRefresh()

            let refreshed = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in self.stakingBalancesRequestCount() > requestsBefore },
                object: nil
            )
            guard XCTWaiter().wait(for: [refreshed], timeout: Constants.refreshSettleTimeout) == .completed else {
                continue
            }

            let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
            if XCTWaiter().wait(for: [expectation], timeout: Constants.refreshSettleTimeout) == .completed {
                return
            }
        }
        XCTFail("Timed out waiting: \(description)")
    }

    private func stakingBalancesRequestCount() -> Int {
        wireMockClient.requestCountSync(method: Constants.Endpoint.post, urlPathPattern: Constants.Endpoint.stakingBalances)
    }
}

private extension StakingPolHotWalletUITests {
    struct UnstakeResult {
        let details: StakingDetailsScreen
        let totalBefore: String
        let availableBefore: String
        let ethereumBefore: Decimal
    }

    enum Constants {
        static let polToken = "POL (ex-MATIC)"
        static let ethereumToken = "Ethereum"

        enum Scenario {
            static let portfolio = "user_tokens_api"
            static let balances = "moralis_evm_token_balances_api"
            static let staking = "staking_eth_pol_balances"
            static let yield = "staking_eth_pol_yield"
            static let ethereumBalance = "eth_network_balance"
        }

        enum State {
            static let hotWalletPortfolio = "HotWalletSvS"
            static let polStakingBalances = "PolStakingEthereum"
            static let started = "Started"
            static let withdrawable = "Withdrawable"
            static let rewardsOverOne = "RewardsOverOne"
            static let stakedLarge = "StakedLarge"
            static let unstakingLarge = "UnstakingLarge"
            static let partiallyUnstaking = "PartiallyUnstaking"
            static let partialUnstake = "PartialUnstake"
            static let afterUnstake = "AfterUnstake"
        }

        enum Amount {
            static let rewards = "1.50"
            static let staked = "5.00"
            static let unstakeInput = "2"
            static let unstaked = "2.00"
            static let remaining = "3.00"
        }

        enum Endpoint {
            static let post = "POST"
            static let stakingBalances = "/stake_api/v1/yields/balances"
        }

        static let refreshAttempts = 6
        static let refreshSettleTimeout: TimeInterval = 10
    }
}
