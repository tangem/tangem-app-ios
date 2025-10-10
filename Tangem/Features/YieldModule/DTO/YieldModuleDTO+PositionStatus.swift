//
//  YieldModuleDTO+PositionStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

extension YieldModuleDTO.Response {
    struct PositionInfo: Decodable, Equatable {
        let tokenAddress: String
        let tokenSymbol: String
        let userBalance: BigUInt
        let earnedYield: BigUInt
        let currentApy: Decimal
        let totalDeposited: BigUInt
        let moduleAddress: String
        let status: String
        let lastUpdateAt: Date

        enum CodingKeys: String, CodingKey {
            case tokenAddress
            case tokenSymbol
            case userBalance
            case earnedYield
            case currentApy
            case totalDeposited
            case moduleAddress
            case status
            case lastUpdateAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            tokenAddress = try container.decode(String.self, forKey: .tokenAddress)
            tokenSymbol = try container.decode(String.self, forKey: .tokenSymbol)

            guard let userBalance = BigUInt(try container.decode(String.self, forKey: .userBalance)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .userBalance,
                    in: container,
                    debugDescription: "userBalance cannot be converted to BigUInt"
                )
            }
            self.userBalance = userBalance

            guard let earnedYield = BigUInt(try container.decode(String.self, forKey: .earnedYield)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .earnedYield,
                    in: container,
                    debugDescription: "earnedYield cannot be converted to BigUInt"
                )
            }
            self.earnedYield = earnedYield

            guard let totalDeposited = BigUInt(try container.decode(String.self, forKey: .totalDeposited)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .totalDeposited,
                    in: container,
                    debugDescription: "totalDeposited cannot be converted to BigUInt"
                )
            }
            self.totalDeposited = totalDeposited

            guard let currentApy = try container.decode(FlexibleDecimal.self, forKey: .currentApy).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .currentApy,
                    in: container,
                    debugDescription: "currentApy cannot be converted to Decimal"
                )
            }
            self.currentApy = currentApy

            moduleAddress = try container.decode(String.self, forKey: .moduleAddress)
            status = try container.decode(String.self, forKey: .status)

            lastUpdateAt = try container.decode(Date.self, forKey: .lastUpdateAt)
        }
    }
}
