//
//  EthEarnProducts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStaking

enum EthEarnProducts {
    static let pooledStakingPerformanceFee = Decimal(8) / 100

    static func make(stakingApy: Decimal?, lendingApy: Decimal?) -> [EarnYieldPickerProduct] {
        var products: [EarnYieldPickerProduct] = []

        if let stakingApy {
            products.append(.pooledStaking(apy: stakingApy, performanceFee: pooledStakingPerformanceFee))
        }

        if let lendingApy {
            // [REDACTED_TODO_COMMENT]
            products.append(.lendingOnAave(apy: lendingApy, incentiveApy: nil, performanceFee: LendingOnAave.performanceFee, auditReportURL: nil))
        }

        return products
    }

    static func bestProduct(in products: [EarnYieldPickerProduct]) -> EarnYieldPickerProduct? {
        products.max { $0.apy < $1.apy }
    }

    static func banner(
        staking: Staking,
        lendingApy: LoadingResult<Decimal, Error>,
        lendingPosition: LoadingResult<Decimal, Never>
    ) -> Banner? {
        switch (staking, lendingPosition) {
        case (.loading, _), (_, .loading):
            return .loading
        default:
            break
        }

        let lendingBalance = lendingPosition.value ?? 0
        var active: [Position] = []
        var stakingApy: Decimal?

        switch staking {
        case .staked(let balance, let apy):
            active.append(Position(id: .pooledStaking, balance: balance, apy: apy))
        case .available(let apy):
            stakingApy = apy
        case .loading, .unavailable:
            break
        }

        if lendingBalance > 0 {
            active.append(Position(id: .lendingOnAave, balance: lendingBalance, apy: lendingApy.value))
        }

        let inactive = make(stakingApy: stakingApy, lendingApy: lendingBalance > 0 ? nil : lendingApy.value)

        guard active.isEmpty else {
            return .yieldEnabled(active: active, inactive: inactive)
        }

        if case .loading = lendingApy {
            return .loading
        }

        return bestProduct(in: inactive).map { .earn(products: inactive, best: $0) }
    }

    static func staking(from state: StakingManagerState) -> Staking {
        switch state {
        case .availableToStake(let info):
            return .available(apy: info.rewardRateValues.max)
        case .staked(let staked):
            return .staked(balance: staked.balances.stakes().sum(), apy: state.apy ?? staked.yieldInfo.rewardRateValues.max)
        case .loading(let cached):
            return cachedStake(cached) ?? .loading
        case .loadingError(_, let cached), .unavailableInRegion(let cached), .temporaryUnavailable(_, let cached):
            return cachedStake(cached) ?? .unavailable
        case .notEnabled:
            return .unavailable
        }
    }

    static func stakingRoute(for state: StakingManagerState) -> StakingRoute? {
        switch state {
        case .staked:
            return .staking
        case .unavailableInRegion:
            return .regionUnavailable
        case .loading, .loadingError, .temporaryUnavailable, .availableToStake, .notEnabled:
            return nil
        }
    }
}

// MARK: - Private

private extension EthEarnProducts {
    static func cachedStake(_ cached: CachedStakingManagerState?) -> Staking? {
        guard let cached, case .staked(let balance) = cached.stakeState else {
            return nil
        }

        return .staked(balance: balance, apy: cached.apy)
    }
}

// MARK: - Banner

extension EthEarnProducts {
    enum Staking: Equatable {
        case loading
        case available(apy: Decimal)
        case staked(balance: Decimal, apy: Decimal)
        case unavailable
    }

    enum Banner: Equatable {
        case loading
        case earn(products: [EarnYieldPickerProduct], best: EarnYieldPickerProduct)
        case yieldEnabled(active: [Position], inactive: [EarnYieldPickerProduct])
    }

    struct Position: Equatable {
        let id: EarnYieldPickerProduct.ID
        let balance: Decimal
        let apy: Decimal?
    }

    enum StakingRoute: Equatable {
        case staking
        case regionUnavailable
    }
}
