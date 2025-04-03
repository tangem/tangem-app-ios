//
//  StakingPendingActionConstraint.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingPendingActionConstraint: Hashable {
    public let type: StakingPendingActionInfo.ActionType
    public let amount: Amount

    public struct Amount: Hashable {
        public let minimum: Decimal?
        public let maximum: Decimal?
    }
}
