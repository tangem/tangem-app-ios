//
//  SolanaUnstakingAmountValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemTestKit
@testable import TangemStaking
@testable import Tangem

@Suite("SolanaUnstakingAmountValidator")
final class SolanaUnstakingAmountValidatorTests: LeakTrackingTestSuite {
    @Test("Zero amount throws zeroAmount")
    func zeroAmountThrows() {
        let sut = makeSUT(stakedAmount: stakedBalance, exitMinimum: 1)

        #expect(throws: SendAmountValidatorError.self) {
            try sut.validate(amount: 0)
        }
    }

    @Test("Amount exceeding staked balance throws amountExceedsStakingBalance")
    func amountExceedsBalanceThrows() {
        let sut = makeSUT(stakedAmount: 5, exitMinimum: 1)

        #expect(throws: UnstakingValidationError.amountExceedsStakingBalance) {
            try sut.validate(amount: 6)
        }
    }

    @Test("Full unstake of stake below minimum passes")
    func fullUnstakeBelowMinimumPasses() {
        let smallStake = Decimal(string: "0.098090754")!
        let sut = makeSUT(stakedAmount: smallStake, exitMinimum: 1)

        #expect(throws: Never.self) {
            try sut.validate(amount: smallStake)
        }
    }

    @Test("Full unstake of stake above minimum passes")
    func fullUnstakeAboveMinimumPasses() {
        let sut = makeSUT(stakedAmount: stakedBalance, exitMinimum: 1)

        #expect(throws: Never.self) {
            try sut.validate(amount: stakedBalance)
        }
    }

    @Test("Partial unstake below minimum throws amountRequirementError")
    func partialUnstakeBelowMinimumThrows() {
        let sut = makeSUT(stakedAmount: stakedBalance, exitMinimum: 1)

        #expect(throws: UnstakingValidationError.amountRequirementError(minAmount: 1)) {
            try sut.validate(amount: Decimal(string: "0.5")!)
        }
    }

    @Test("Partial unstake leaving remainder below minimum throws remainingAmountBelowMinimum")
    func partialUnstakeRemainderBelowMinimumThrows() {
        let sut = makeSUT(stakedAmount: stakedBalance, exitMinimum: 1)

        #expect(throws: UnstakingValidationError.remainingAmountBelowMinimum) {
            try sut.validate(amount: 5)
        }
    }

    @Test("Partial unstake violating both minimums throws amountRequirementError")
    func bothMinimumViolationsThrowAmountRequirementError() {
        let sut = makeSUT(stakedAmount: Decimal(string: "1.5")!, exitMinimum: 1)

        #expect(throws: UnstakingValidationError.amountRequirementError(minAmount: 1)) {
            try sut.validate(amount: Decimal(string: "0.7")!)
        }
    }

    @Test("Partial unstake with both parts above minimum passes")
    func validPartialUnstakePasses() {
        let sut = makeSUT(stakedAmount: stakedBalance, exitMinimum: 1)

        #expect(throws: Never.self) {
            try sut.validate(amount: Decimal(string: "1.5")!)
        }
    }

    @Test("Amount exactly at minimum passes")
    func amountAtMinimumBoundaryPasses() {
        let sut = makeSUT(stakedAmount: stakedBalance, exitMinimum: 1)

        #expect(throws: Never.self) {
            try sut.validate(amount: 1)
        }
    }

    @Test("Remainder exactly at minimum passes")
    func remainderAtMinimumBoundaryPasses() {
        let sut = makeSUT(stakedAmount: 5, exitMinimum: 1)

        #expect(throws: Never.self) {
            try sut.validate(amount: 4)
        }
    }

    @Test("Zero minimum from StakeKit keeps partial unstake allowed")
    func zeroMinimumKeepsPartialUnstakeAllowed() {
        let sut = makeSUT(stakedAmount: Decimal(string: "0.098090754")!, exitMinimum: 0)

        #expect(throws: Never.self) {
            try sut.validate(amount: Decimal(string: "0.098")!)
        }
    }

    @Test("Zero exit minimum falls back to enter minimum")
    func zeroExitMinimumFallsBackToEnterMinimum() {
        let sut = makeSUT(stakedAmount: stakedBalance, exitMinimum: 0, enterMinimum: 1)

        #expect(throws: UnstakingValidationError.amountRequirementError(minAmount: 1)) {
            try sut.validate(amount: Decimal(string: "0.5")!)
        }
    }

    @Test("Partial unstake passes while minimum is not loaded")
    func notLoadedMinimumKeepsPartialUnstakeAllowed() {
        let sut = makeSUT(stakedAmount: stakedBalance, state: .notEnabled)

        #expect(throws: Never.self) {
            try sut.validate(amount: Decimal(string: "0.5")!)
        }
    }

    @Test("Minimum arriving after construction activates validation")
    func minimumArrivingLaterActivatesValidation() {
        let subject = CurrentValueSubject<StakingManagerState, Never>(.notEnabled)
        let sut = trackForMemoryLeaks(
            SolanaUnstakingAmountValidator(
                stakedAmount: stakedBalance,
                stakingManagerStatePublisher: subject.eraseToAnyPublisher()
            )
        )

        #expect(throws: Never.self) {
            try sut.validate(amount: Decimal(string: "0.5")!)
        }

        subject.send(.staked(.init(balances: [], yieldInfo: makeYieldInfo(exitMinimum: 1), canStakeMore: true)))

        #expect(throws: UnstakingValidationError.amountRequirementError(minAmount: 1)) {
            try sut.validate(amount: Decimal(string: "0.5")!)
        }
    }
}

// MARK: - Helpers

private extension SolanaUnstakingAmountValidatorTests {
    var stakedBalance: Decimal { Decimal(string: "5.158034614")! }

    func makeSUT(stakedAmount: Decimal, exitMinimum: Decimal, enterMinimum: Decimal = .zero) -> SolanaUnstakingAmountValidator {
        let state = StakingManagerState.staked(
            .init(balances: [], yieldInfo: makeYieldInfo(exitMinimum: exitMinimum, enterMinimum: enterMinimum), canStakeMore: true)
        )
        return makeSUT(stakedAmount: stakedAmount, state: state)
    }

    func makeSUT(stakedAmount: Decimal, state: StakingManagerState) -> SolanaUnstakingAmountValidator {
        let sut = SolanaUnstakingAmountValidator(
            stakedAmount: stakedAmount,
            stakingManagerStatePublisher: CurrentValueSubject(state).eraseToAnyPublisher()
        )
        return trackForMemoryLeaks(sut)
    }

    func makeYieldInfo(exitMinimum: Decimal, enterMinimum: Decimal = .zero) -> StakingYieldInfo {
        StakingYieldInfo(
            id: "solana-sol-native-multivalidator-staking",
            isAvailable: true,
            rewardType: .apy,
            rewardRateValues: RewardRateValues(aprs: [0.05], rewardRate: .zero),
            enterMinimumRequirement: enterMinimum,
            exitMinimumRequirement: exitMinimum,
            targets: [],
            preferredTargets: [],
            item: StakingTokenItem(network: .solana, name: "Solana", decimals: 9, symbol: "SOL"),
            unbondingPeriod: .constant(days: 3),
            warmupPeriod: .constant(days: 0),
            rewardClaimingType: .auto,
            rewardScheduleType: .daily,
            maximumStakeAmount: nil
        )
    }
}
