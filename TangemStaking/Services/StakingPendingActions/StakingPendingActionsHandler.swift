//
//  StakingPendingActionsHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingPendingActionsHandler {
    func mergeBalancesAndPendingActions(
        balances: [StakingBalance],
        actions: [PendingAction]?,
        yield: StakingYieldInfo
    ) -> [StakingBalance]
}

extension StakingPendingActionsHandler {
    func mapToStakingBalance(
        action: PendingAction,
        yield: StakingYieldInfo,
        balanceType: StakingBalanceType
    ) -> StakingBalance {
        let targetType: StakingTargetType = {
            guard let address = action.targetAddress,
                  let target = yield.targets.first(where: { $0.address == address }) else {
                return .empty
            }

            return .target(target)
        }()

        return StakingBalance(
            item: yield.item,
            amount: action.amount,
            balanceType: balanceType,
            targetType: targetType,
            inProgress: true,
            actions: []
        )
    }
}
