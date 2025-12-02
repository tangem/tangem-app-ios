//
//  CachedStakingManagerState.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct CachedStakingManagerState: Codable, Hashable {
    let rewardType: CachedRewardType
    let apy: Decimal
    let stakeState: CachedStakeState
}
