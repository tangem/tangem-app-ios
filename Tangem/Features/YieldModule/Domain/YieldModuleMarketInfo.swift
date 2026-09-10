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

    /// The APY to display: the campaign-boosted total when a Merkl campaign is active, the base APY otherwise.
    /// The total comes from the backend as is — the app never sums APY components locally.
    var effectiveApy: Decimal {
        incentive?.totalApyEst ?? apy
    }
}

/// Merkl campaign overlay of an active market, in the same fraction form as `apy`.
/// `rewardsApr` is net of the Tangem service fee.
struct YieldModuleMarketIncentive: Codable, Equatable {
    let rewardsApr: Decimal
    let totalApyEst: Decimal
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
            incentive: includeIncentive
                ? Self.makeIncentive(hasActiveCampaign: dto.hasActiveCampaign, rewardsApr: dto.rewardsApr, totalApyEst: dto.totalApyEst)
                : nil
        )
    }

    init(from cached: CachedYieldModuleMarket, includeIncentive: Bool) {
        self.init(
            tokenContractAddress: cached.tokenContractAddress,
            apy: cached.apy / 100,
            isActive: cached.isActive,
            chainId: cached.chainId,
            maxFeeNative: cached.maxFeeNative,
            maxFeeUSD: cached.maxFeeUSD,
            incentive: includeIncentive
                ? Self.makeIncentive(hasActiveCampaign: cached.hasActiveCampaign, rewardsApr: cached.rewardsApr, totalApyEst: cached.totalApyEst)
                : nil
        )
    }

    private static func makeIncentive(
        hasActiveCampaign: Bool?,
        rewardsApr: Decimal?,
        totalApyEst: Decimal?
    ) -> YieldModuleMarketIncentive? {
        guard hasActiveCampaign == true, let rewardsApr, let totalApyEst else {
            return nil
        }

        return YieldModuleMarketIncentive(
            rewardsApr: rewardsApr / 100,
            totalApyEst: totalApyEst / 100
        )
    }
}
