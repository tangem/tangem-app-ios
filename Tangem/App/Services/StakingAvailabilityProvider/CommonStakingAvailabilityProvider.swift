//
//  CommonStakingAvailabilityProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct CommonStakingAvailabilityProvider: StakingAvailabilityProvider {
    @Injected(\.stakingRepositoryProxy) private var repository: StakingRepositoryProxy

    init() {}

    func isAvailableForStaking(item: StakingTokenItem) -> Bool {
        repository.getYield(item: item) != nil
    }
}
