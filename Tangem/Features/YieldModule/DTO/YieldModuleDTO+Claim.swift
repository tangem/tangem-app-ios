//
//  YieldModuleDTO+Claim.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

extension YieldModuleDTO.Response {
    struct ClaimCalldata: Decodable, Equatable {
        let chainId: Int
        let userAddress: String
        let moduleAddress: String?
        let hasClaimable: Bool
        let to: String?
        let data: String?
        let rewardTokens: [String]
        /// Opaque cumulative distributor amounts — never interpreted, only length-checked against `rewardTokens`.
        let cumulativeAmounts: [String]
        let totalEstimatedServiceFeeUsd: Decimal
        let claimRecommended: Bool

        enum CodingKeys: String, CodingKey {
            case chainId
            case userAddress
            case moduleAddress
            case hasClaimable
            case to
            case data
            case rewardTokens
            case cumulativeAmounts
            case totalEstimatedServiceFeeUsd
            case claimRecommended
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            chainId = try container.decode(Int.self, forKey: .chainId)
            userAddress = try container.decode(String.self, forKey: .userAddress)
            moduleAddress = try container.decodeIfPresent(String.self, forKey: .moduleAddress)
            hasClaimable = try container.decode(Bool.self, forKey: .hasClaimable)
            to = try container.decodeIfPresent(String.self, forKey: .to)
            data = try container.decodeIfPresent(String.self, forKey: .data)
            rewardTokens = try container.decode([String].self, forKey: .rewardTokens)
            cumulativeAmounts = try container.decode([String].self, forKey: .cumulativeAmounts)

            guard let totalEstimatedServiceFeeUsd = try container.decode(
                FlexibleDecimal.self,
                forKey: .totalEstimatedServiceFeeUsd
            ).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .totalEstimatedServiceFeeUsd,
                    in: container,
                    debugDescription: "totalEstimatedServiceFeeUsd cannot be converted to Decimal"
                )
            }
            self.totalEstimatedServiceFeeUsd = totalEstimatedServiceFeeUsd

            claimRecommended = try container.decode(Bool.self, forKey: .claimRecommended)
        }
    }

    struct ClaimHistory: Decodable, Equatable {
        let moduleAddress: String?
        let claims: [ClaimHistoryEntry]
    }

    struct ClaimHistoryEntry: Decodable, Equatable {
        let tokenAddress: String
        let amount: BigUInt
        /// Unix seconds.
        let timestamp: TimeInterval

        enum CodingKeys: String, CodingKey {
            case tokenAddress
            case amount
            case timestamp
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            tokenAddress = try container.decode(String.self, forKey: .tokenAddress)

            guard let amount = BigUInt(try container.decode(String.self, forKey: .amount)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .amount,
                    in: container,
                    debugDescription: "amount cannot be converted to BigUInt"
                )
            }
            self.amount = amount

            timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        }
    }
}
