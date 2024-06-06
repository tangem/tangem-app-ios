//
//  StakingRepositoryProxy.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

typealias StakingRepositoryProxy = StakingRepository & Initializable

private struct StakingRepositoryProxyKey: InjectionKey {
    static var currentValue: StakingRepositoryProxy = CommonStakingRepositoryProxy()
}

extension InjectedValues {
    var stakingRepositoryProxy: StakingRepositoryProxy {
        get { Self[StakingRepositoryProxyKey.self] }
        set { Self[StakingRepositoryProxyKey.self] = newValue }
    }
}
