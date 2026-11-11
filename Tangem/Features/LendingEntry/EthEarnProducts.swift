//
//  EthEarnProducts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

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

    static func banner(staking: Staking, lendingApy: LoadingResult<Decimal, Error>) -> Banner? {
        switch (staking, lendingApy) {
        case (.staked, _):
            return nil
        case (.loading, _), (_, .loading):
            return .loading
        default:
            break
        }

        let stakingApy: Decimal? = switch staking {
        case .available(let apy): apy
        case .loading, .staked, .unavailable: nil
        }

        let products = make(stakingApy: stakingApy, lendingApy: lendingApy.value)

        return bestProduct(in: products).map { .earn(products: products, best: $0) }
    }
}

// MARK: - Banner

extension EthEarnProducts {
    enum Staking: Equatable {
        case loading
        case available(apy: Decimal)
        case staked
        case unavailable
    }

    enum Banner: Equatable {
        case loading
        case earn(products: [EarnYieldPickerProduct], best: EarnYieldPickerProduct)
    }
}
