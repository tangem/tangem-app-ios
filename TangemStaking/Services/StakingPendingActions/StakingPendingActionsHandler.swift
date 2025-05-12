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
        yield: YieldInfo
    ) -> [StakingBalance]
}

extension StakingPendingActionsHandler {
    func mapToStakingBalance(
        action: PendingAction,
        yield: YieldInfo,
        balanceType: StakingBalanceType
    ) -> StakingBalance {
        let validatorType: StakingValidatorType = {
            guard let address = action.validatorAddress,
                  let validator = yield.validators.first(where: { $0.address == address }) else {
                return .empty
            }

            return .validator(validator)
        }()

        return StakingBalance(
            item: yield.item,
            amount: action.amount,
            balanceType: balanceType,
            validatorType: validatorType,
            inProgress: true,
            actions: []
        )
    }
}
