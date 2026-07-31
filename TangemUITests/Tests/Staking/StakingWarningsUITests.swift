//
//  StakingWarningsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StakingWarningsUITests: BaseTestCase {
    func testUnstakeRentFeeWarning() {
        setAllureId(2196)

        launchColdSolanaStaking(stakingState: Constants.staked, senderBalance: Constants.rentBalance, recipientRent: true)

        openSolanaToken()
            .tapNativeStakingBlock()
            .assertYourStakesTitle()
            .assertActiveStakeDisplayed()
            .tapActiveStake()
            .waitForDisplay()
            .tapMaxAmount()
            .goToSummary()
            .assertRentFeeWarningAndConfirmDisabled()
    }

    func testStakeRentFeeWarning() {
        setAllureId(2233)

        launchColdSolanaStaking(stakingState: Constants.empty, senderBalance: Constants.stakeRentBalance, recipientRent: false)

        openSolanaToken()
            .tapNativeStakingBlock()
            .proceedToSendScreen()
            .waitForDisplay()
            .enterStakingAmount(Constants.stakeAmount)
            .goToSummary()
            .assertRentFeeWarningAndConfirmDisabled()
    }

    func testWithdrawRentFeeWarning() {
        setAllureId(10331)

        launchColdSolanaStaking(stakingState: Constants.withdrawable, senderBalance: Constants.rentBalance, recipientRent: true)

        openSolanaToken()
            .tapNativeStakingBlock()
            .assertYourStakesTitle()
            .assertWithdrawEntryDisplayed()
            .tapWithdrawEntry()
            .assertRentFeeWarningAndConfirmDisabled()
    }

    private func launchColdSolanaStaking(stakingState: String, senderBalance: String?, recipientRent: Bool) {
        var scenarios = [
            ScenarioConfig(name: Constants.portfolioScenario, initialState: Constants.solanaPortfolio),
            ScenarioConfig(name: Constants.stakingScenario, initialState: stakingState),
        ]

        if let senderBalance {
            scenarios.append(ScenarioConfig(name: Constants.senderBalanceScenario, initialState: senderBalance))
        }

        if recipientRent {
            scenarios.append(ScenarioConfig(name: Constants.rentRecipientScenario, initialState: Constants.rentBalance))
        }

        launchApp(
            tangemApiType: .mock,
            stakingApiType: .mock,
            scenarios: scenarios
        )
    }

    private func openSolanaToken() -> TokenScreen {
        let tokenScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.solanaToken)
        // Staking block renders only once staking data has loaded; refresh to force it (as in the Yield tests).
        pullToRefresh()
        return tokenScreen.waitForStakingInfo()
    }

    private enum Constants {
        static let solanaToken = "Solana"

        static let portfolioScenario = "user_tokens_api"
        static let solanaPortfolio = "Solana"

        static let stakingScenario = "staking_sol_balances"
        static let staked = "Staked"
        static let withdrawable = "Withdrawable"
        static let empty = "Empty"

        static let rentRecipientScenario = "solana_get_account_info_recipient"
        static let senderBalanceScenario = "solana_balance"
        static let rentBalance = "RentBalance"
        /// Balance above the stake minimum but low enough that staking `stakeAmount` leaves less than the rent exemption.
        static let stakeRentBalance = "StakeRentBalance"

        static let stakeAmount = "0.0375"
    }
}
