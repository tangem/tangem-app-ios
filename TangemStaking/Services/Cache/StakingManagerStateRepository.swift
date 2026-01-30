//
//  StakingManagerStateRepository.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import CryptoKit

public protocol StakingManagerStateRepository {
    func storeState(_ state: StakingManagerState, cacheId: String)
    func state(cacheId: String) -> CachedStakingManagerState?
    func clearState(cacheId: String)
}

public final class CommonStakingManagerStateRepository {
    private let storage: CachesDirectoryStorage

    public init(storage: CachesDirectoryStorage) {
        self.storage = storage
    }
}

extension CommonStakingManagerStateRepository: StakingManagerStateRepository {
    public func storeState(_ state: StakingManagerState, cacheId: String) {
        guard let cachedStakeState = mapToCachedStakeState(state),
              let rewardType = state.rewardType,
              let apy = state.apy else { return }

        let stateToCache = CachedStakingManagerState(
            rewardType: mapToCachedRewardType(rewardType),
            apy: apy,
            stakeState: cachedStakeState,
            date: Date()
        )

        updateState { currentState in
            currentState.updateValue(stateToCache, forKey: cacheId)
        }
    }

    public func state(cacheId: String) -> CachedStakingManagerState? {
        let currentState = getCurrentState()
        return currentState[cacheId]
    }

    public func clearState(cacheId: String) {
        updateState { currentState in
            currentState.removeValue(forKey: cacheId)
        }
    }

    private func updateState(_ updateBlock: (inout [String: CachedStakingManagerState]) -> Void) {
        var currentState = getCurrentState()

        updateBlock(&currentState)

        try? storage.storeAndWait(value: currentState)
    }

    private func getCurrentState() -> [String: CachedStakingManagerState] {
        (try? storage.value()) ?? .init()
    }
}

private extension CommonStakingManagerStateRepository {
    func mapToCachedRewardType(_ rewardType: RewardType) -> CachedRewardType {
        switch rewardType {
        case .apy: .apy
        case .apr: .apr
        }
    }

    func mapToCachedStakeState(_ state: StakingManagerState) -> CachedStakeState? {
        switch state {
        case .availableToStake: .availableToStake
        case .staked(let stakedInfo): .staked(balance: stakedInfo.balances.blocked().sum())
        default: nil
        }
    }
}
