//
//  StakingYieldInfoProvider+Injected.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

private struct StakingYieldInfoProviderKey: InjectionKey {
    static var currentValue: StakingYieldInfoProvider = {
        let factory = StakingDependenciesFactory()

        let lockPublisher = InjectedValues[\.userWalletRepository].eventProvider
            .compactMap { event -> Void? in
                if case .locked = event { return () }
                return nil
            }
            .eraseToAnyPublisher()

        let provider = CommonStakingYieldInfoProvider(
            stakeKitAPIProvider: factory.makeStakeKitAPIProvider(),
            p2pAPIProvider: factory.makeP2PAPIProvider(),
            targetAmountLimitProvider: factory.targetAmountLimitProvider,
            cacheInvalidationPublisher: lockPublisher
        )

        return provider
    }()
}

extension InjectedValues {
    var stakingYieldInfoProvider: StakingYieldInfoProvider {
        get { Self[StakingYieldInfoProviderKey.self] }
        set { Self[StakingYieldInfoProviderKey.self] = newValue }
    }
}
