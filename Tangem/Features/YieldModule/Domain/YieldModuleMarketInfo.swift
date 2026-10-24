//
//  YieldModuleMarketInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct YieldModuleMarketInfo: Codable, Equatable {
    let tokenContractAddress: String
    let apy: Decimal
    let isActive: Bool
    let chainId: Int?
    let maxFeeNative: Decimal?
    let maxFeeUSD: Decimal?
    let incentive: YieldModuleMarketIncentive?

    /// The total comes from the backend as is — the app never sums APY components locally.
    var effectiveApy: Decimal {
        incentive?.grossTotalApyEst ?? apy
    }
}

/// Merkl campaign overlay of an active market, in the same fraction form as `apy`.
/// Surfaces that show the reward component hide it when `grossRewardsApy` is `nil`.
struct YieldModuleMarketIncentive: Codable, Equatable {
    let grossRewardsApy: Decimal?
    let netRewardsApy: Decimal?
    let grossTotalApyEst: Decimal
    let netTotalApyEst: Decimal?
}

extension YieldModuleMarketInfo {
    init(dto: YieldModuleDTO.Response.MarketInfo, includeIncentive: Bool) {
        self.init(
            tokenContractAddress: dto.tokenAddress,
            apy: dto.apy / 100,
            isActive: dto.isActive,
            chainId: dto.chainId,
            maxFeeNative: dto.maxFeeNative,
            maxFeeUSD: dto.maxFeeUSD,
            incentive: includeIncentive ? Self.makeIncentive(dto: dto) : nil
        )
    }

    init(from cached: CachedYieldModuleMarket) {
        self.init(
            tokenContractAddress: cached.tokenContractAddress,
            apy: cached.apy / 100,
            isActive: cached.isActive,
            chainId: cached.chainId,
            maxFeeNative: cached.maxFeeNative,
            maxFeeUSD: cached.maxFeeUSD,
            incentive: nil
        )
    }

    private static func makeIncentive(dto: YieldModuleDTO.Response.MarketInfo) -> YieldModuleMarketIncentive? {
        // A missing `grossRewardsApy` must not kill the whole overlay — only the reward-component surfaces need it.
        guard dto.hasActiveCampaign == true, let grossTotalApyEst = dto.grossTotalApyEst else {
            return nil
        }

        return YieldModuleMarketIncentive(
            grossRewardsApy: dto.grossRewardsApy.map { $0 / 100 },
            netRewardsApy: dto.netRewardsApy.map { $0 / 100 },
            grossTotalApyEst: grossTotalApyEst / 100,
            netTotalApyEst: dto.netTotalApyEst.map { $0 / 100 }
        )
    }
}
