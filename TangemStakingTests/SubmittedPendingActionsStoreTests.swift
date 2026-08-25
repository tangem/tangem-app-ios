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

    // MARK: - Fixtures

    private func makeStore() -> SubmittedPendingActionsStore {
        CommonSubmittedPendingActionsStore(lifetime: 180)
    }

    private func stakeAction(amount: Decimal) -> StakingAction {
        makeAction(amount: amount, type: .stake)
    }

    private func makeAction(amount: Decimal, type: StakingAction.ActionType) -> StakingAction {
        StakingAction(amount: amount, targetType: .target(target(address: validatorAddress)), type: type)
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
            status: .active
        )
    }

    private func activeBalance(amount: Decimal) -> StakingBalanceInfo {
        StakingBalanceInfo(
            item: tokenItem,
            amount: amount,
            balanceType: .active,
            targetAddress: validatorAddress,
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
