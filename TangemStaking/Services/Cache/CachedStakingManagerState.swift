//
//  CachedStakingManagerState.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct CachedStakingManagerState: Codable, Hashable {
    public let rewardType: CachedRewardType
    public let apy: Decimal
    public let stakeState: CachedStakeState
    public let date: Date
}
