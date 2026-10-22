//
//  SubmittedPendingActionsStoreTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemStaking

struct SubmittedPendingActionsStoreTests {
    private let validatorAddress = "EQBNL2W5KZuw3Y3FbrLdDfIdXdrYXQFfcGfDO3kig0EK8zxz"
    private let otherValidatorAddress = "EQBFbbSCrAnX2XWOjSq2qnAx_GRdx2wZIFqrlk9D0-1mxHDN"

    private let tokenItem = StakingTokenItem(network: .ton, name: "Toncoin", decimals: 9, symbol: "TON")

    // MARK: - Seeding

    @Test
    func registeredStakeIsReturnedWhileServerListIsEmptyAndBalancesUnchanged() {
        let store = makeStore()
        let balances = [activeBalance(amount: 10)]

        _ = store.mergeWithServerActions([], currentBalances: balances)
        store.register(action: stakeAction(amount: 11))

        let merged = store.mergeWithServerActions([], currentBalances: balances)

        #expect(merged.count == 1)
        #expect(merged.first?.type == .stake)
        #expect(merged.first?.status == .processing)
        #expect(merged.first?.amount == 11)
        #expect(merged.first?.targetAddress == validatorAddress)
    }

    @Test
    func actionTypesAreMappedToPendingActionTypes() {
        let store = makeStore()
        _ = store.mergeWithServerActions([], currentBalances: [])

        store.register(action: makeAction(amount: 1, type: .unstake))
        store.register(action: makeAction(amount: 2, type: .pending(.withdraw(passthroughs: []))))

        let merged = store.mergeWithServerActions([], currentBalances: [])

        #expect(merged.map(\.type) == [.unstake, .withdraw])
    }

    // MARK: - Handing over to the server list

    @Test
    func serverCounterpartReplacesSubmittedAction() {
        let store = makeStore()
        let balances = [activeBalance(amount: 10)]

        _ = store.mergeWithServerActions([], currentBalances: balances)
        store.register(action: stakeAction(amount: 11))

        let serverAction = pendingAction(id: "server-id", type: .stake, amount: 11, targetAddress: validatorAddress)
        let merged = store.mergeWithServerActions([serverAction], currentBalances: balances)

        #expect(merged.count == 1)
        #expect(merged.first?.id == "server-id")

        // and the submitted action must not resurface after the server action drains
        let afterDrain = store.mergeWithServerActions([], currentBalances: balances)
        #expect(afterDrain.isEmpty)
    }

    @Test
    func unrelatedServerActionDoesNotReplaceSubmittedAction() {
        let store = makeStore()
        let balances = [activeBalance(amount: 10)]

        _ = store.mergeWithServerActions([], currentBalances: balances)
        store.register(action: stakeAction(amount: 11))

        let serverAction = pendingAction(id: "server-id", type: .stake, amount: 5, targetAddress: otherValidatorAddress)
        let merged = store.mergeWithServerActions([serverAction], currentBalances: balances)

        #expect(merged.count == 2)
        #expect(merged.contains(where: { $0.id == "server-id" }))
        #expect(merged.contains(where: { $0.targetAddress == validatorAddress && $0.amount == 11 }))
    }

    // MARK: - Completion detection

    @Test
    func balanceChangeAgainstBaselineDropsSubmittedAction() {
        let store = makeStore()

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        store.register(action: stakeAction(amount: 11))

        let changedBalances = [activeBalance(amount: 21)]
        let merged = store.mergeWithServerActions([], currentBalances: changedBalances)
        #expect(merged.isEmpty)

        // stays dropped even if balances change back
        let mergedAgain = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        #expect(mergedAgain.isEmpty)
    }

    @Test
    func lifetimeExpiryDropsSubmittedAction() {
        var currentDate = Date(timeIntervalSinceReferenceDate: 0)
        let store = CommonSubmittedPendingActionsStore(lifetime: 180, now: { currentDate })
        let balances = [activeBalance(amount: 10)]

        _ = store.mergeWithServerActions([], currentBalances: balances)
        store.register(action: stakeAction(amount: 11))

        currentDate = currentDate.addingTimeInterval(179)
        #expect(store.mergeWithServerActions([], currentBalances: balances).count == 1)

        currentDate = currentDate.addingTimeInterval(2)
        #expect(store.mergeWithServerActions([], currentBalances: balances).isEmpty)
    }

    // MARK: - Reflected in balances

    @Test
    func serverActionAlreadyReflectedInBalancesIsHidden() {
        let store = makeStore()

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        store.prepare(action: unstakeAction(amount: 4))

        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let merged = store.mergeWithServerActions([serverAction], currentBalances: balancesAfterUnstake)

        #expect(merged.isEmpty)
    }

    @Test
    func serverActionNotYetReflectedInBalancesIsShown() {
        let store = makeStore()
        let balances = [activeBalance(amount: 10)]

        _ = store.mergeWithServerActions([], currentBalances: balances)
        store.prepare(action: unstakeAction(amount: 4))

        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let merged = store.mergeWithServerActions([serverAction], currentBalances: balances)

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func registerAfterBalancesAreReflectedUsesBaselineFromPreparation() {
        let store = makeStore()

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        store.prepare(action: unstakeAction(amount: 4))
        _ = store.mergeWithServerActions([], currentBalances: balancesAfterUnstake)
        store.register(action: unstakeAction(amount: 4))

        let merged = store.mergeWithServerActions([], currentBalances: balancesAfterUnstake)

        #expect(merged.isEmpty)
    }

    @Test
    func reflectedServerActionStaysHiddenAfterLifetime() {
        var currentDate = Date(timeIntervalSinceReferenceDate: 0)
        let store = CommonSubmittedPendingActionsStore(lifetime: 180, now: { currentDate })
        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        store.prepare(action: unstakeAction(amount: 4))
        store.register(action: unstakeAction(amount: 4))
        _ = store.mergeWithServerActions([serverAction], currentBalances: balancesAfterUnstake)

        currentDate = currentDate.addingTimeInterval(600)
        let merged = store.mergeWithServerActions([serverAction], currentBalances: balancesAfterUnstake)

        #expect(merged.isEmpty)
    }

    @Test
    func rewardsChangeDoesNotHideServerAction() {
        let store = makeStore()

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10), balance(amount: 1, type: .rewards)])
        store.prepare(action: unstakeAction(amount: 4))

        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let merged = store.mergeWithServerActions(
            [serverAction],
            currentBalances: [activeBalance(amount: 10), balance(amount: 1.1, type: .rewards)]
        )

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func unbondingDateChangeDoesNotHideServerAction() {
        let store = makeStore()
        let unbondingAt = Date(timeIntervalSince1970: 1_000)

        _ = store.mergeWithServerActions(
            [],
            currentBalances: [activeBalance(amount: 10), balance(amount: 3, type: .unbonding(date: unbondingAt))]
        )
        store.prepare(action: unstakeAction(amount: 4))

        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let merged = store.mergeWithServerActions(
            [serverAction],
            currentBalances: [
                activeBalance(amount: 10),
                balance(amount: 3, type: .unbonding(date: unbondingAt.addingTimeInterval(10))),
            ]
        )

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func preparedActionOutlivesLongSigning() {
        var currentDate = Date(timeIntervalSinceReferenceDate: 0)
        let store = CommonSubmittedPendingActionsStore(lifetime: 180, now: { currentDate })
        let balances = [activeBalance(amount: 10)]

        _ = store.mergeWithServerActions([], currentBalances: balances)
        store.prepare(action: unstakeAction(amount: 4))

        currentDate = currentDate.addingTimeInterval(300)
        _ = store.mergeWithServerActions([], currentBalances: balances)

        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let merged = store.mergeWithServerActions([serverAction], currentBalances: balancesAfterUnstake)

        #expect(merged.isEmpty)
    }

    @Test
    func claimedRewardsAreReflectedByRewardsChange() {
        let store = makeStore()

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10), balance(amount: 1, type: .rewards)])
        store.prepare(action: makeAction(amount: 1, type: .pending(.claimRewards(passthrough: ""))))
        store.register(action: makeAction(amount: 1, type: .pending(.claimRewards(passthrough: ""))))

        let merged = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])

        #expect(merged.isEmpty)
    }

    @Test
    func rewardsAccrualDoesNotReflectClaim() {
        let store = makeStore()
        let claim = makeAction(amount: 1, type: .pending(.claimRewards(passthrough: "")))
        let serverAction = pendingAction(id: "server-id", type: .claimRewards, amount: 1, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10), balance(amount: 1, type: .rewards)])
        store.prepare(action: claim)
        store.register(action: claim)

        let merged = store.mergeWithServerActions(
            [serverAction],
            currentBalances: [activeBalance(amount: 10), balance(amount: 1.1, type: .rewards)]
        )

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func reorderedBalancesDoNotHideServerAction() {
        let store = makeStore()
        let active = balance(amount: 10, type: .active, accountAddress: "stake-1")
        let unbonding = balance(amount: 3, type: .unbonding(date: nil), accountAddress: "stake-2")

        _ = store.mergeWithServerActions([], currentBalances: [active, unbonding])
        store.prepare(action: unstakeAction(amount: 4))

        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let merged = store.mergeWithServerActions([serverAction], currentBalances: [unbonding, active])

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func reflectedActionHidesOnlyOneOfIdenticalServerActions() {
        let store = makeStore()

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        store.prepare(action: unstakeAction(amount: 4))
        store.register(action: unstakeAction(amount: 4))
        _ = store.mergeWithServerActions([], currentBalances: balancesAfterUnstake)

        store.prepare(action: unstakeAction(amount: 4))
        store.register(action: unstakeAction(amount: 4))

        let first = pendingAction(id: "first", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let second = pendingAction(id: "second", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let merged = store.mergeWithServerActions([first, second], currentBalances: balancesAfterUnstake)

        #expect(merged.map(\.id) == ["second"])
    }

    @Test
    func serverActionHandsOverOnlyOneOfIdenticalSubmissions() {
        let store = makeStore()
        let balances = [activeBalance(amount: 10)]

        _ = store.mergeWithServerActions([], currentBalances: balances)
        store.prepare(action: unstakeAction(amount: 4))
        store.register(action: unstakeAction(amount: 4))
        store.prepare(action: unstakeAction(amount: 4))
        store.register(action: unstakeAction(amount: 4))

        let first = pendingAction(id: "first", type: .unstake, amount: 4, targetAddress: validatorAddress)
        let second = pendingAction(id: "second", type: .unstake, amount: 4, targetAddress: validatorAddress)

        let mergedWithFirst = store.mergeWithServerActions([first], currentBalances: balances)
        #expect(mergedWithFirst.count == 2)
        #expect(mergedWithFirst.first?.id == "first")

        let mergedWithBoth = store.mergeWithServerActions([first, second], currentBalances: balances)
        #expect(mergedWithBoth.map(\.id) == ["first", "second"])
    }

    @Test
    func laterActionStaysInProgressUntilItsOwnBalancesArrive() {
        let store = makeStore()
        let first = pendingAction(id: "first", type: .stake, amount: 1, targetAddress: validatorAddress)
        let second = pendingAction(id: "second", type: .stake, amount: 2, targetAddress: validatorAddress)
        let balancesBefore = [activeBalance(amount: 10)]
        let balancesAfterFirst = balancesBefore + [balance(amount: 1, type: .warmup, accountAddress: "stake-2")]
        let balancesAfterBoth = balancesAfterFirst + [balance(amount: 2, type: .warmup, accountAddress: "stake-3")]

        _ = store.mergeWithServerActions([], currentBalances: balancesBefore)
        store.prepare(action: stakeAction(amount: 1))
        store.register(action: stakeAction(amount: 1))
        store.prepare(action: stakeAction(amount: 2))
        store.register(action: stakeAction(amount: 2))

        let afterFirst = store.mergeWithServerActions([first], currentBalances: balancesAfterFirst)
        #expect(afterFirst.map(\.amount) == [2])

        let reported = store.mergeWithServerActions([first, second], currentBalances: balancesAfterFirst)
        #expect(reported.map(\.id) == ["second"])

        let afterBoth = store.mergeWithServerActions([first, second], currentBalances: balancesAfterBoth)
        #expect(afterBoth.isEmpty)
    }

    @Test
    func refreshesDuringPartialUnstakeNeverReturnReflectedAction() {
        let store = makeStore()
        let unstakeAmount: Decimal = 1.0118
        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: unstakeAmount, targetAddress: validatorAddress)
        let balancesBefore = [balance(amount: 2.052775655, type: .active, accountAddress: "stake-1")]
        let balancesAfter: (TimeInterval) -> [StakingBalanceInfo] = { offset in
            [
                balance(
                    amount: 1.01346624,
                    type: .unbonding(date: Date(timeIntervalSince1970: 1_000 + offset)),
                    accountAddress: "stake-2"
                ),
                balance(amount: 1.040975655, type: .active, accountAddress: "stake-1"),
            ]
        }

        _ = store.mergeWithServerActions([], currentBalances: balancesBefore)
        store.prepare(action: unstakeAction(amount: unstakeAmount))
        #expect(store.mergeWithServerActions([], currentBalances: balancesBefore).isEmpty)

        #expect(store.mergeWithServerActions([serverAction], currentBalances: balancesAfter(1)).isEmpty)
        #expect(store.mergeWithServerActions([serverAction], currentBalances: balancesAfter(2)).isEmpty)

        store.register(action: unstakeAction(amount: unstakeAmount))

        #expect(store.mergeWithServerActions([], currentBalances: balancesAfter(3)).isEmpty)
        #expect(store.mergeWithServerActions([serverAction], currentBalances: balancesAfter(4)).isEmpty)
        #expect(store.mergeWithServerActions([], currentBalances: balancesAfter(5)).isEmpty)
    }

    // MARK: - Reflected by the action's own balances

    @Test
    func actionsOnDifferentValidatorsAreReflectedByTheirOwnBalances() {
        let store = makeStore()
        let first = pendingAction(id: "first", type: .stake, amount: 1, targetAddress: validatorAddress)
        let second = pendingAction(id: "second", type: .stake, amount: 2, targetAddress: otherValidatorAddress)
        let secondStake = makeAction(amount: 2, type: .stake, targetAddress: otherValidatorAddress)
        let balancesBefore = [activeBalance(amount: 10)]
        let balancesAfterSecond = balancesBefore + [
            balance(amount: 2, type: .warmup, accountAddress: "stake-2", targetAddress: otherValidatorAddress),
        ]

        _ = store.mergeWithServerActions([], currentBalances: balancesBefore)
        store.prepare(action: stakeAction(amount: 1))
        store.register(action: stakeAction(amount: 1))
        store.prepare(action: secondStake)
        store.register(action: secondStake)

        let merged = store.mergeWithServerActions([first, second], currentBalances: balancesAfterSecond)

        #expect(merged.map(\.id) == ["first"])
    }

    @Test
    func warmupBecomingActiveDoesNotReflectStake() {
        let store = makeStore()
        let serverAction = pendingAction(id: "server-id", type: .stake, amount: 1, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions(
            [],
            currentBalances: [activeBalance(amount: 10), balance(amount: 2, type: .warmup, accountAddress: "stake-2")]
        )
        store.prepare(action: stakeAction(amount: 1))

        let merged = store.mergeWithServerActions(
            [serverAction],
            currentBalances: [activeBalance(amount: 10), balance(amount: 2, type: .active, accountAddress: "stake-2")]
        )

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func epochRewardsAddedToStakeDoNotReflectUnstake() {
        let store = makeStore()
        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        store.prepare(action: unstakeAction(amount: 4))

        let merged = store.mergeWithServerActions([serverAction], currentBalances: [activeBalance(amount: 10.01)])

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func epochRewardsAddedToStakeDoNotReflectStake() {
        let store = makeStore()
        let serverAction = pendingAction(id: "server-id", type: .stake, amount: 4, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        store.prepare(action: stakeAction(amount: 4))

        let merged = store.mergeWithServerActions([serverAction], currentBalances: [activeBalance(amount: 10.01)])

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func slashingDoesNotReflectUnstake() {
        let store = makeStore()
        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions([], currentBalances: [activeBalance(amount: 10)])
        store.prepare(action: unstakeAction(amount: 4))

        let merged = store.mergeWithServerActions([serverAction], currentBalances: [activeBalance(amount: 9.99)])

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func finishedUnbondingDoesNotReflectUnstake() {
        let store = makeStore()
        let serverAction = pendingAction(id: "server-id", type: .unstake, amount: 4, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions(
            [],
            currentBalances: [activeBalance(amount: 10), balance(amount: 3, type: .unbonding(date: nil), accountAddress: "stake-2")]
        )
        store.prepare(action: unstakeAction(amount: 4))

        let merged = store.mergeWithServerActions(
            [serverAction],
            currentBalances: [activeBalance(amount: 10), balance(amount: 3, type: .unstaked, accountAddress: "stake-2")]
        )

        #expect(merged.map(\.id) == ["server-id"])
    }

    @Test
    func tailOfEarlierUnstakeDoesNotReflectLaterStake() {
        let store = makeStore()
        let firstAccount = balance(amount: 10, type: .active, accountAddress: "stake-1")
        let secondAccount = balance(amount: 2, type: .active, accountAddress: "stake-2")
        let firstAccountUnstaked = [
            balance(amount: 6, type: .active, accountAddress: "stake-1"),
            balance(amount: 4, type: .unbonding(date: nil), accountAddress: "stake-3"),
        ]

        _ = store.mergeWithServerActions([], currentBalances: [firstAccount, secondAccount])
        store.prepare(action: unstakeAction(amount: 4))
        store.register(action: unstakeAction(amount: 4))
        _ = store.mergeWithServerActions([], currentBalances: firstAccountUnstaked + [secondAccount])

        store.prepare(action: stakeAction(amount: 1))
        store.register(action: stakeAction(amount: 1))

        let merged = store.mergeWithServerActions(
            [],
            currentBalances: firstAccountUnstaked + [balance(amount: 2, type: .unbonding(date: nil), accountAddress: "stake-2")]
        )

        #expect(merged.map(\.amount) == [1])
    }

    @Test
    func withdrawIsReflectedWhenUnstakedBalanceIsWithdrawn() {
        let store = makeStore()
        let withdraw = makeAction(amount: 3, type: .pending(.withdraw(passthroughs: [])))
        let serverAction = pendingAction(id: "server-id", type: .withdraw, amount: 3, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions(
            [],
            currentBalances: [activeBalance(amount: 10), balance(amount: 3, type: .unstaked, accountAddress: "stake-2")]
        )
        store.prepare(action: withdraw)

        let merged = store.mergeWithServerActions([serverAction], currentBalances: [activeBalance(amount: 10)])

        #expect(merged.isEmpty)
    }

    @Test
    func voteLockedIsReflectedWhenActiveBalanceGrows() {
        let store = makeStore()
        let vote = makeAction(amount: 5, type: .pending(.voteLocked(passthrough: "")))
        let serverAction = pendingAction(id: "server-id", type: .voteLocked, amount: 5, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions([], currentBalances: [untargetedBalance(amount: 5, type: .locked)])
        store.prepare(action: vote)

        let merged = store.mergeWithServerActions([serverAction], currentBalances: [activeBalance(amount: 5)])

        #expect(merged.isEmpty)
    }

    @Test
    func unlockLockedIsReflectedWhenLockedBalanceShrinks() {
        let store = makeStore()
        let unlock = makeAction(amount: 5, type: .pending(.unlockLocked(passthrough: "")))
        let serverAction = pendingAction(id: "server-id", type: .unlockLocked, amount: 5, targetAddress: validatorAddress)

        _ = store.mergeWithServerActions([], currentBalances: [untargetedBalance(amount: 5, type: .locked)])
        store.prepare(action: unlock)

        let merged = store.mergeWithServerActions(
            [serverAction],
            currentBalances: [untargetedBalance(amount: 5, type: .unbonding(date: nil))]
        )

        #expect(merged.isEmpty)
    }

    // MARK: - Fixtures

    private var balancesAfterUnstake: [StakingBalanceInfo] {
        [activeBalance(amount: 6), balance(amount: 4, type: .unbonding(date: nil))]
    }

    private func makeStore() -> SubmittedPendingActionsStore {
        CommonSubmittedPendingActionsStore(lifetime: 180)
    }

    private func stakeAction(amount: Decimal) -> StakingAction {
        makeAction(amount: amount, type: .stake)
    }

    private func unstakeAction(amount: Decimal) -> StakingAction {
        makeAction(amount: amount, type: .unstake)
    }

    private func makeAction(amount: Decimal, type: StakingAction.ActionType, targetAddress: String? = nil) -> StakingAction {
        StakingAction(amount: amount, targetType: .target(target(address: targetAddress ?? validatorAddress)), type: type)
    }

    private func target(address: String) -> StakingTargetInfo {
        StakingTargetInfo(
            address: address,
            name: "Chorus One Pool #2",
            preferred: true,
            partner: false,
            image: nil,
            rewardType: .apy,
            rewardRate: 0.04,
            status: .active,
            allowsPartialUnstake: true
        )
    }

    private func activeBalance(amount: Decimal) -> StakingBalanceInfo {
        balance(amount: amount, type: .active)
    }

    private func balance(
        amount: Decimal,
        type: StakingBalanceType,
        accountAddress: String? = nil,
        targetAddress: String? = nil
    ) -> StakingBalanceInfo {
        StakingBalanceInfo(
            item: tokenItem,
            amount: amount,
            accountAddress: accountAddress,
            balanceType: type,
            targetAddress: targetAddress ?? validatorAddress,
            actions: []
        )
    }

    private func untargetedBalance(amount: Decimal, type: StakingBalanceType) -> StakingBalanceInfo {
        StakingBalanceInfo(
            item: tokenItem,
            amount: amount,
            accountAddress: nil,
            balanceType: type,
            targetAddress: nil,
            actions: []
        )
    }

    private func pendingAction(
        id: String,
        type: StakingPendingActionInfo.ActionType,
        amount: Decimal,
        targetAddress: String
    ) -> PendingAction {
        PendingAction(
            id: id,
            status: .processing,
            amount: amount,
            type: type,
            currentStepIndex: 0,
            transactions: [],
            targetAddress: targetAddress
        )
    }
}
