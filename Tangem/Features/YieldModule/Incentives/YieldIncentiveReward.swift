//
//  YieldIncentiveReward.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

struct YieldIncentiveReward: Equatable {
    enum Destination: String, Equatable {
        case module
        case owner
        case aave
        case unsupported
    }

    let rewardTokenAddress: String
    let symbol: String
    let decimals: Int
    let claimableAmount: BigUInt
    let pendingAmount: BigUInt
    let usdValue: Decimal
    let serviceFeeRateBps: Int
    let estimatedServiceFeeUsd: Decimal
    let estimatedNetValueUsd: Decimal
    let destination: Destination

    var isSupported: Bool {
        switch destination {
        case .module, .owner, .aave:
            return true
        case .unsupported:
            return false
        }
    }

    var isClaimable: Bool {
        claimableAmount > 0 && isSupported
    }

    var estimatedNetClaimableAmount: BigUInt {
        let netRateBps = Constants.maxServiceFeeRateBps - serviceFeeRateBps

        return claimableAmount * BigUInt(netRateBps) / BigUInt(Constants.maxServiceFeeRateBps)
    }
}

private extension YieldIncentiveReward {
    enum Constants {
        static let maxServiceFeeRateBps = 10_000
    }
}

extension YieldIncentiveReward {
    init(dto: YieldModuleDTO.Response.IncentiveReward) {
        self.init(
            rewardTokenAddress: dto.rewardToken,
            symbol: dto.symbol,
            decimals: dto.tokenDecimals,
            claimableAmount: dto.claimableAmount,
            pendingAmount: dto.pendingAmount,
            usdValue: dto.usdValue,
            serviceFeeRateBps: clamp(dto.serviceFeeRateBps, min: 0, max: Constants.maxServiceFeeRateBps),
            estimatedServiceFeeUsd: dto.estimatedServiceFeeUsd,
            estimatedNetValueUsd: dto.estimatedNetValueUsd,
            destination: Destination(rawValue: dto.finalDestination.lowercased()) ?? .unsupported
        )
    }
}
