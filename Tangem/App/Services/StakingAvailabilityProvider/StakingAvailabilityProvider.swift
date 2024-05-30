//
//  StakingAvailabilityProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

public protocol StakingAvailabilityProvider {
    func isAvailableForStaking(item: StakingTokenItem) -> Bool
}

private struct StakingAvailabilityProviderKey: InjectionKey {
    static var currentValue: StakingAvailabilityProvider = CommonStakingAvailabilityProvider()
}

extension InjectedValues {
    var stakingAvailabilityProvider: StakingAvailabilityProvider {
        get { Self[StakingAvailabilityProviderKey.self] }
        set { Self[StakingAvailabilityProviderKey.self] = newValue }
    }
}
