//
//  EarnApyResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct EarnApyResolver {
    /// Active product wins; higher APY breaks ties.
    func resolve(for walletModel: any WalletModel) -> EarnApyInfo? {
        let candidates = [walletModel.yieldSupplyEarnInfo, walletModel.stakingEarnInfo].compactMap { $0 }

        let activeCandidates = candidates.filter(\.isActive)
        return activeCandidates.max(by: \.apy) ?? candidates.max(by: \.apy)
    }
}

// MARK: - Private helpers

private extension WalletModel {
    var yieldSupplyEarnInfo: EarnApyInfo? {
        guard let stateInfo = yieldModuleManager?.state else {
            return nil
        }

        // Active (or entering/exiting) position outlives an admin-disabled market; the flag only gates non-active tokens.
        guard !stateInfo.state.isEffectivelyActive, !stateInfo.state.isProcessing else {
            return EarnApyInfo(isActive: true, apy: stateInfo.marketInfo?.apy ?? 0, product: .yieldSupply)
        }

        guard let marketInfo = stateInfo.marketInfo, marketInfo.isActive else {
            return nil
        }

        return EarnApyInfo(isActive: false, apy: marketInfo.apy, product: .yieldSupply)
    }

    var stakingEarnInfo: EarnApyInfo? {
        guard let stakingManager else {
            return nil
        }

        let state = stakingManager.state
        switch state {
        case .availableToStake, .staked, .loading, .loadingError, .unavailableInRegion:
            // apy/isActive fall back to the cached state, so a refresh's `.loading` doesn't drop the token.
            guard let apy = state.apy else {
                return nil
            }

            return EarnApyInfo(isActive: state.isActive, apy: apy, product: .staking)
        case .notEnabled, .temporaryUnavailable:
            return nil
        }
    }
}
