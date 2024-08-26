//
//  StakingAction.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingAction: Hashable {
    public let amount: Decimal
    public let validator: String
    public let type: ActionType

    public init(amount: Decimal, validator: String, type: StakingAction.ActionType) {
        self.amount = amount
        self.validator = validator
        self.type = type
    }

    public enum ActionType: Hashable {
        case stake
        case unstake
        case pending(PendingActionType)
    }
}
