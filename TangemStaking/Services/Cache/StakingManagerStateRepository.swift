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
    func storeState(_ state: StakingManagerState)
    func state() -> CachedStakingManagerState?
    func clearState()
}

public final class CommonStakingManagerStateRepository {
    private let storage: CachesDirectoryStorage
    private let stakingWallet: StakingWallet

    public init(stakingWallet: StakingWallet, storage: CachesDirectoryStorage) {
        self.stakingWallet = stakingWallet
        self.storage = storage
    }
}

extension CommonStakingManagerStateRepository: StakingManagerStateRepository {
    public func storeState(_ state: StakingManagerState) {
        guard let cachedStakeState = mapToCachedStakeState(state),
              let rewardType = state.rewardType,
              let apy = state.apy else { return }

        let stateToCache = CachedStakingManagerState(
            rewardType: mapToCachedRewardType(rewardType),
            apy: apy,
            stakeState: cachedStakeState,
            date: Date()
        )

        updateUserWalletState { stateForUserWallet in
            stateForUserWallet.updateValue(stateToCache, forKey: stakingWallet.cacheId)
        }
    }

    public func state() -> CachedStakingManagerState? {
        let currentState = getCurrentState()

        return currentState[stakingWallet.cacheId]
    }

    public func clearState() {
        updateUserWalletState { stateForUserWallet in
            stateForUserWallet.removeValue(forKey: stakingWallet.cacheId)
        }
    }

    private func updateUserWalletState(_ updateBlock: (inout [String: CachedStakingManagerState]) -> Void) {
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

private extension StakingWallet {
    var cacheId: String {
        let digest = SHA256.hash(data: publicKey)
        let hash = Data(digest).hexString
        return "\(item.network)_\(item.contractAddress ?? "coin")_\(hash)"
    }
}
