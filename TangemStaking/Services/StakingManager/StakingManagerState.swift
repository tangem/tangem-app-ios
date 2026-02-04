//
//  StakingManagerState.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public enum StakingManagerState: Hashable, CustomStringConvertible {
    case loading(cached: CachedStakingManagerState? = nil)
    case notEnabled
    case loadingError(String, cached: CachedStakingManagerState? = nil)
    // When we turn off the YieldInfo in the admin panel
    case temporaryUnavailable(StakingYieldInfo, cached: CachedStakingManagerState? = nil)
    case availableToStake(StakingYieldInfo)
    case staked(Staked)

    public var yieldInfo: StakingYieldInfo? {
        switch self {
        case .loading, .notEnabled, .loadingError:
            return nil
        case .temporaryUnavailable(let yieldInfo, _), .availableToStake(let yieldInfo):
            return yieldInfo
        case .staked(let staked):
            return staked.yieldInfo
        }
    }

    public var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var isSuccessfullyLoaded: Bool {
        switch self {
        case .staked, .availableToStake:
            return true
        default:
            return false
        }
    }

    public func stakesCount(for target: StakingTargetInfo) -> Int? {
        switch self {
        case .staked(let staked):
            staked.balances.filter { $0.targetType.target?.address == target.address }.count
        default: nil
        }
    }

    public var description: String {
        switch self {
        case .loading: "loading"
        case .notEnabled: "notEnabled"
        case .loadingError(let error, _): "loadingError \(error)"
        case .temporaryUnavailable: "temporaryUnavailable"
        case .availableToStake: "availableToStake"
        case .staked: "staked"
        }
    }

    public var apy: Decimal? {
        switch self {
        case .availableToStake(let stakingYieldInfo):
            stakingYieldInfo.apy
        case .staked(let staked):
            staked.balances.apy(fallbackAPY: staked.yieldInfo.apy)
        case .loading(let cached), .loadingError(_, let cached):
            cached?.apy
        default:
            nil
        }
    }

    public var rewardType: RewardType? {
        switch self {
        case .availableToStake(let stakingYieldInfo):
            stakingYieldInfo.rewardType
        case .staked(let staked):
            staked.yieldInfo.rewardType
        case .loading(.some(let cached)), .loadingError(_, .some(let cached)):
            switch cached.rewardType {
            case .apy: .apy
            case .apr: .apr
            }
        default:
            nil
        }
    }

    public var isActive: Bool {
        switch self {
        case .availableToStake: false
        case .staked: true
        case .loading(.some(let cached)), .loadingError(_, .some(let cached)):
            switch cached.stakeState {
            case .availableToStake: false
            case .staked: true
            }
        default:
            false
        }
    }
}

public extension StakingYieldInfo {
    var apy: Decimal {
        switch rewardRateValues {
        case .single(let apy): apy
        case .interval(_, let maxAPY): maxAPY
        }
    }
}

public extension StakingManagerState {
    struct Staked: Hashable {
        public let balances: [StakingBalance]
        public let yieldInfo: StakingYieldInfo
        public let canStakeMore: Bool
    }
}
