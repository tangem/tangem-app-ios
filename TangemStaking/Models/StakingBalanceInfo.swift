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
    public let blocked: Decimal
    public let rewards: Decimal?
    public let balanceGroupType: BalanceGroupType

    public init(item: StakingTokenItem, blocked: Decimal, rewards: Decimal?, balanceGroupType: BalanceGroupType) {
        self.item = item
        self.blocked = blocked
        self.rewards = rewards
        self.balanceGroupType = balanceGroupType
    }
}

public enum BalanceGroupType {
    case active
    case unstaked
    case unknown

    var isActiveOrUnstaked: Bool {
        self == .active || self == .unstaked
    }
}
