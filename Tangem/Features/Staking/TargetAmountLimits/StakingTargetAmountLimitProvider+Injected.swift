//
//  StakingTargetAmountLimitProvider+Injected.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

private struct StakingTargetAmountLimitProviderKey: InjectionKey {
    static var currentValue: CommonStakingTargetAmountLimitProvider = .init(
        tangemApiService: InjectedValues[\.tangemApiService],
        userWalletEventProvider: InjectedValues[\.userWalletRepository].eventProvider
    )
}

extension InjectedValues {
    var stakingTargetAmountLimitProvider: CommonStakingTargetAmountLimitProvider {
        get { Self[StakingTargetAmountLimitProviderKey.self] }
        set { Self[StakingTargetAmountLimitProviderKey.self] = newValue }
    }
}
