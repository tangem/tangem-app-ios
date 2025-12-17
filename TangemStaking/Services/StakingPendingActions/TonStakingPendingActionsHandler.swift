//
//  TonStakingPendingActionsHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Changing one staking position in TON affects
/// all the positions of the same validator
struct TonStakingPendingActionsHandler: StakingPendingActionsHandler {
    func mergeBalancesAndPendingActions(
        balances: [StakingBalance],
        actions: [PendingAction]?,
        yield: StakingYieldInfo
    ) -> [StakingBalance] {
        guard let actions, !actions.isEmpty else { return balances }
        var result = [StakingBalance]()

        var matchingActions = [PendingAction]()

        // make all the balances matching validator active
        balances.forEach { balance in
            let matchingAction = actions.first(where: {
                $0.targetAddress != nil && $0.targetAddress == balance.targetType.target?.address
            })

            if let matchingAction {
                let updatedBalance = StakingBalance(
                    item: balance.item,
                    amount: balance.amount,
                    accountAddress: balance.accountAddress,
                    balanceType: balance.balanceType,
                    targetType: balance.targetType,
                    inProgress: true,
                    actions: balance.actions
                )
                result.append(updatedBalance)
                matchingActions.append(matchingAction)
            } else {
                result.append(balance)
            }
        }

        // if we didn't find any balance to modify add dummy balance
        for action in actions {
            if !matchingActions.contains(where: { $0.id == action.id }) {
                let balance = mapToStakingBalance(action: action, yield: yield, balanceType: .active)
                result.append(balance)
            }
        }

        return result
    }
}
