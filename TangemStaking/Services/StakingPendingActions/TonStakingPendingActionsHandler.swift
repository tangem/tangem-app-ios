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
        yield: YieldInfo
    ) -> [StakingBalance] {
        guard let actions, !actions.isEmpty else { return balances }
        var result = [StakingBalance]()

        if let stakeAction = actions.first(where: { $0.type == .stake }) {
            result.append(mapToStakingBalance(action: stakeAction, yield: yield, balanceType: .active))
        }

        // make all the balances matching validator active
        balances.forEach { balance in
            let validatorMatch: Bool = actions.contains(where: {
                $0.type != .stake && $0.validatorAddress == balance.validatorType.validator?.address
            })

            if validatorMatch {
                let updatedBalance = StakingBalance(
                    item: balance.item,
                    amount: balance.amount,
                    accountAddress: balance.accountAddress,
                    balanceType: balance.balanceType,
                    validatorType: balance.validatorType,
                    inProgress: true,
                    actions: balance.actions
                )
                result.append(updatedBalance)
            } else {
                result.append(balance)
            }
        }

        return result
    }
}
