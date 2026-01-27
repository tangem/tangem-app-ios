//
//  CommonStakingPendingActionsHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonStakingPendingActionsHandler: StakingPendingActionsHandler {
    func mergeBalancesAndPendingActions(
        balances: [StakingBalance],
        actions: [PendingAction]?,
        yield: StakingYieldInfo
    ) -> [StakingBalance] {
        guard let actions, !actions.isEmpty else { return balances }
        var result = balances
        actions.forEach { action in
            switch action.type {
            case .voteLocked, .vote:
                if let lockedBalanceIndex = balanceIndexByType(balances: result, action: action, type: .locked) {
                    result.remove(at: lockedBalanceIndex)
                }
                fallthrough
            case .stake:
                result.append(mapToStakingBalance(action: action, yield: yield, balanceType: .active))
            case .withdraw:
                modifyBalancesByStatus(
                    balances: &result,
                    action: action,
                    type: .unstaked,
                    reduceBalanceByActionAmount: false,
                    makeInProgress: true
                )
            case .unlockLocked:
                modifyBalancesByStatus(
                    balances: &result,
                    action: action,
                    type: .locked,
                    reduceBalanceByActionAmount: false,
                    makeInProgress: true
                )
            case .unstake where isFullAmountUnstaking(for: result, action: action):
                // make existing staking in progress
                modifyBalancesByStatus(
                    balances: &result,
                    action: action,
                    type: .active,
                    reduceBalanceByActionAmount: false,
                    makeInProgress: true
                )
            case .unstake:
                // for partial unstake reduce amount of existing staking and append new in progress block
                modifyBalancesByStatus(
                    balances: &result,
                    action: action,
                    type: .active,
                    reduceBalanceByActionAmount: true,
                    makeInProgress: false
                )
                result.append(mapToStakingBalance(action: action, yield: yield, balanceType: .active))
            default:
                break // do nothing
            }
        }

        return result
    }

    private func isFullAmountUnstaking(for balances: [StakingBalance], action: PendingAction) -> Bool {
        guard let index = balanceIndexByType(balances: balances, action: action, type: .active) else {
            StakingLogger.info("Couldn't find corresponding staked balance for unstake action")
            return false
        }
        let balance = balances[index]
        return balance.amount == action.amount
    }

    private func balanceIndexByType(
        balances: [StakingBalance],
        action: PendingAction,
        type: StakingBalanceType
    ) -> Int? {
        balances.firstIndex(where: {
            !$0.inProgress
                && $0.balanceType == type
                && $0.targetType.target?.address == action.targetAddress
                && $0.accountAddress.flatMap { action.accountAddresses?.contains($0) } ?? true
        })
    }

    private func modifyBalancesByStatus(
        balances: inout [StakingBalance],
        action: PendingAction,
        type: StakingBalanceType,
        reduceBalanceByActionAmount: Bool,
        makeInProgress inProgress: Bool
    ) {
        guard let index = balanceIndexByType(balances: balances, action: action, type: type) else { return }

        let balance = balances[index]

        let amount = reduceBalanceByActionAmount ? balance.amount - action.amount : balance.amount

        let updatedBalance = StakingBalance(
            item: balance.item,
            amount: amount,
            accountAddress: balance.accountAddress,
            balanceType: balance.balanceType,
            targetType: balance.targetType,
            inProgress: inProgress,
            actions: balance.actions
        )

        balances[index] = updatedBalance
    }
}
