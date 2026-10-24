//
//  StakingSolanaStakeMoreUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class StakingSolanaStakeMoreUITests: BaseTestCase {
    func testStakeMoreWithSameValidator() {
        setAllureId(11574)

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: Constants.Scenario.portfolio, initialState: Constants.State.portfolio),
                ScenarioConfig(name: Constants.Scenario.walletBalance, initialState: Constants.State.walletBalanceFunded),
                ScenarioConfig(name: Constants.Scenario.stakingBalances, initialState: Constants.State.stakingBalancesStaked),
                ScenarioConfig(name: Constants.Scenario.stakingActions, initialState: Constants.State.stakingActionsStarted),
                ScenarioConfig(name: Constants.Scenario.stakingYield, initialState: Constants.State.stakingYieldAutoClaiming),
            ]
        )

        let tokenScreen = importHotWallet()
            .tapToken(Constants.tokenName)
            .waitForNonZeroTotalBalance()

        let totalBefore = tokenScreen
            .pullToRefresh()
            .waitForStakingInfo()
            .waitForNonZeroTotalBalance()
            .getTotalBalance()
        let availableBefore = tokenScreen.tapAvailableSegment().getAvailableBalance()
        XCTAssertTrue(
            tokenScreen.getStakingBalanceCrypto().contains(Constants.Amount.settled),
            "Staking block should show the staked amount '\(Constants.Amount.settled)'"
        )

        let summaryScreen = tokenScreen
            .tapNativeStakingBlock()
            .assertAutoClaimedRewardsText(Localization.stakingSolanaDetailsAutoClaimingRewardsDailyText)
            .assertSettledStake(validator: Constants.validatorName, amount: Constants.Amount.settled)
            .assertStakeButtonLabel(Localization.stakingStakeMore)
            .proceedToSendScreen()
            .waitForDisplay()
            .enterStakingAmount(Constants.Amount.stakeMore)
            .goToSummary()
            .waitForDisplay()
            .waitForAmountValue(Constants.Amount.stakeMore)
            .assertValidatorName(Constants.validatorName)

        let finishScreen = summaryScreen
            .tapSendButton()
            .waitForDisplay()
            .assertAmountDisplayed()
            .assertTransactionTimeDisplayed()

        wireMockClient.setScenarioStateSync(Constants.Scenario.walletBalance, state: Constants.State.walletBalanceDone)
        wireMockClient.setScenarioStateSync(Constants.Scenario.stakingActions, state: Constants.State.stakingActionsProcessing)

        let tokenScreenAfterOperation = finishScreen
            .closeToStakingDetails()
            .assertPendingStake(validator: Constants.validatorName, amount: Constants.Amount.pending)
            .assertSettledStake(validator: Constants.validatorName, amount: Constants.Amount.settled)
            .goBack()

        wireMockClient.setScenarioStateSync(Constants.Scenario.stakingBalances, state: Constants.State.stakingBalancesStakedMore)
        wireMockClient.setScenarioStateSync(Constants.Scenario.stakingActions, state: Constants.State.stakingActionsStarted)

        refreshUntil(tokenScreenAfterOperation, "Staking block shows the merged amount") {
            return tokenScreenAfterOperation.loadedStakingBalanceCrypto?.contains(Constants.Amount.merged) == true
        }

        refreshUntil(tokenScreenAfterOperation, "Available balance is decreased by the staked amount") {
            guard let before = Self.fiatValue(availableBefore),
                  let after = tokenScreenAfterOperation.loadedAvailableBalance.flatMap(Self.fiatValue) else {
                return false
            }
            return before - after == Constants.stakeMoreFiat
        }

        tokenScreenAfterOperation.tapTotalSegment()

        waitUntil("Total balance is back to the initial value") {
            tokenScreenAfterOperation.loadedTotalBalance == totalBefore
        }

        tokenScreenAfterOperation
            .tapNativeStakingBlock()
            .assertActiveStakeCount(1)
            .assertSettledStake(validator: Constants.validatorName, amount: Constants.Amount.merged)
            .assertNoPendingStake()
    }

    private func refreshUntil(_ screen: TokenScreen, _ description: String, _ condition: @escaping () -> Bool) {
        for _ in 0 ..< Constants.refreshAttempts {
            screen.pullToRefresh()
            let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
            if XCTWaiter().wait(for: [expectation], timeout: Constants.refreshSettleTimeout) == .completed {
                return
            }
        }
        XCTFail("Timed out waiting: \(description)")
    }

    private func waitUntil(_ description: String, timeout: TimeInterval = .networkRequest, _ condition: @escaping () -> Bool) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, "Timed out waiting: \(description)")
    }

    private static func fiatValue(_ text: String) -> Decimal? {
        Decimal(string: text.filter { $0.isNumber || $0 == "." })
    }
}

private extension StakingSolanaStakeMoreUITests {
    enum Constants {
        static let tokenName = "Solana"
        static let validatorName = "Tangem Validator"
        static let stakeMoreFiat = Decimal(20)
        static let refreshAttempts = 6
        static let refreshSettleTimeout: TimeInterval = 10

        enum Amount {
            static let stakeMore = "0.1"
            static let settled = "1.00"
            static let pending = "0.10"
            static let merged = "1.10"
        }

        enum Scenario {
            static let portfolio = "user_tokens_api"
            static let walletBalance = "solana_balance"
            static let stakingBalances = "staking_sol_balances"
            static let stakingActions = "staking_sol_actions"
            static let stakingYield = "staking_sol_yield"
        }

        enum State {
            static let portfolio = "SolanaHotWalletSvS"
            static let walletBalanceFunded = "StakeMoreFunded"
            static let walletBalanceDone = "StakeMoreDone"
            static let stakingBalancesStaked = "HotWalletStaked"
            static let stakingBalancesStakedMore = "HotWalletStakedMore"
            static let stakingActionsStarted = "Started"
            static let stakingActionsProcessing = "StakeProcessing"
            static let stakingYieldAutoClaiming = "AutoClaiming"
        }
    }
}
