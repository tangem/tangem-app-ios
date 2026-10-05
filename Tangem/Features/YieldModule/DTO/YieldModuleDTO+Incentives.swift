//
//  YieldModuleDTO+Incentives.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

extension YieldModuleDTO.Response {
    struct IncentivesInfo: Decodable, Equatable {
        let moduleAddress: String?
        let rewards: [IncentiveReward]
        let lastUpdatedAt: Date
        let claimRecommended: Bool
    }

    struct IncentiveReward: Decodable, Equatable {
        let rewardToken: String
        let symbol: String
        let tokenDecimals: Int
        let claimableAmount: BigUInt
        let pendingAmount: BigUInt
        let usdValue: Decimal
        let serviceFeeRateBps: Int
        let estimatedServiceFeeUsd: Decimal
        let estimatedNetValueUsd: Decimal
        let finalDestination: String

        enum CodingKeys: String, CodingKey {
            case rewardToken
            case symbol
            case tokenDecimals
            case claimableAmount
            case pendingAmount
            case usdValue
            case serviceFeeRateBps
            case estimatedServiceFeeUsd
            case estimatedNetValueUsd
            case finalDestination
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            rewardToken = try container.decode(String.self, forKey: .rewardToken)
            symbol = try container.decode(String.self, forKey: .symbol)
            tokenDecimals = try container.decode(Int.self, forKey: .tokenDecimals)

            guard let claimableAmount = BigUInt(try container.decode(String.self, forKey: .claimableAmount)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .claimableAmount,
                    in: container,
                    debugDescription: "claimableAmount cannot be converted to BigUInt"
                )
            }
            self.claimableAmount = claimableAmount

            guard let pendingAmount = BigUInt(try container.decode(String.self, forKey: .pendingAmount)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .pendingAmount,
                    in: container,
                    debugDescription: "pendingAmount cannot be converted to BigUInt"
                )
            }
            self.pendingAmount = pendingAmount

            guard let usdValue = try container.decode(FlexibleDecimal.self, forKey: .usdValue).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .usdValue,
                    in: container,
                    debugDescription: "usdValue cannot be converted to Decimal"
                )
            }
            self.usdValue = usdValue

            serviceFeeRateBps = try container.decode(Int.self, forKey: .serviceFeeRateBps)

            guard let estimatedServiceFeeUsd = try container.decode(
                FlexibleDecimal.self,
                forKey: .estimatedServiceFeeUsd
            ).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .estimatedServiceFeeUsd,
                    in: container,
                    debugDescription: "estimatedServiceFeeUsd cannot be converted to Decimal"
                )
            }
            self.estimatedServiceFeeUsd = estimatedServiceFeeUsd

            guard let estimatedNetValueUsd = try container.decode(
                FlexibleDecimal.self,
                forKey: .estimatedNetValueUsd
            ).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .estimatedNetValueUsd,
                    in: container,
                    debugDescription: "estimatedNetValueUsd cannot be converted to Decimal"
                )
            }
            self.estimatedNetValueUsd = estimatedNetValueUsd

            finalDestination = try container.decode(String.self, forKey: .finalDestination)
        }
    }
}
