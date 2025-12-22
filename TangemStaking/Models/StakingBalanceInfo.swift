//
//  StakingBalanceInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingBalanceInfo: Hashable {
    public let item: StakingTokenItem
    public let amount: Decimal
    public let accountAddress: String?
    public let balanceType: StakingBalanceType
    public let targetAddress: String?
    public let actions: [StakingPendingActionInfo]
    public let actionConstraints: [StakingPendingActionConstraint]?

    public init(
        item: StakingTokenItem,
        amount: Decimal,
        accountAddress: String? = nil,
        balanceType: StakingBalanceType,
        targetAddress: String?,
        actions: [StakingPendingActionInfo],
        actionConstraints: [StakingPendingActionConstraint]? = nil
    ) {
        self.item = item
        self.amount = amount
        self.accountAddress = accountAddress
        self.balanceType = balanceType
        self.targetAddress = targetAddress
        self.actions = actions
        self.actionConstraints = actionConstraints
    }
}
