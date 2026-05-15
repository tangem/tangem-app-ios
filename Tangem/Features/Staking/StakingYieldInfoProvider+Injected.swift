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

private final class StakingYieldInfoProviderBuilder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func build() -> StakingYieldInfoProvider {
        let factory = StakingDependenciesFactory()

        let lockPublisher = userWalletRepository.eventProvider
            .filter { $0 == .locked }
            .map { _ in () }
            .eraseToAnyPublisher()

        return CommonStakingYieldInfoProvider(
            stakeKitAPIProvider: factory.makeStakeKitAPIProvider(),
            p2pAPIProvider: factory.makeP2PAPIProvider(),
            targetAmountLimitProvider: factory.targetAmountLimitProvider,
            cacheInvalidationPublisher: lockPublisher
        )
    }
}

private struct StakingYieldInfoProviderKey: InjectionKey {
    static var currentValue: StakingYieldInfoProvider = StakingYieldInfoProviderBuilder().build()
}

extension InjectedValues {
    var stakingYieldInfoProvider: StakingYieldInfoProvider {
        get { Self[StakingYieldInfoProviderKey.self] }
        set { Self[StakingYieldInfoProviderKey.self] = newValue }
    }
}
