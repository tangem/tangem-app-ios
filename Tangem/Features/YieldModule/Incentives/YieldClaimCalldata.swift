//
//  YieldClaimCalldata.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct YieldClaimCalldata: Equatable {
    let chainId: Int
    let userAddress: String
    let moduleAddress: String?
    let hasClaimable: Bool
    let to: String?
    let data: String?
    let rewardTokens: [String]
    let cumulativeAmounts: [String]
    let totalEstimatedServiceFeeUsd: Decimal
    let claimRecommended: Bool
}

extension YieldClaimCalldata {
    init(dto: YieldModuleDTO.Response.ClaimCalldata) {
        self.init(
            chainId: dto.chainId,
            userAddress: dto.userAddress,
            moduleAddress: dto.moduleAddress,
            hasClaimable: dto.hasClaimable,
            to: dto.to,
            data: dto.data,
            rewardTokens: dto.rewardTokens,
            cumulativeAmounts: dto.cumulativeAmounts,
            totalEstimatedServiceFeeUsd: dto.totalEstimatedServiceFeeUsd,
            claimRecommended: dto.claimRecommended
        )
    }
}

struct YieldClaimHistoryEntry: Equatable {
    let tokenAddress: String
    let amount: BigUInt
    let date: Date
}

extension YieldClaimHistoryEntry {
    init(dto: YieldModuleDTO.Response.ClaimHistoryEntry) {
        self.init(
            tokenAddress: dto.tokenAddress,
            amount: dto.amount,
            date: Date(timeIntervalSince1970: dto.timestamp)
        )
    }
}
