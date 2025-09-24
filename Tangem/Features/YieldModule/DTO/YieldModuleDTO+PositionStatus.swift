//
//  YieldModuleDTO+PositionStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

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

            currentApy = try container.decode(Decimal.self, forKey: .currentApy)
            moduleAddress = try container.decode(String.self, forKey: .moduleAddress)
            status = try container.decode(String.self, forKey: .status)

            let dateString = try container.decode(String.self, forKey: .lastUpdateAt)
            let formatter = ISO8601DateFormatter()
            guard let date = formatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .lastUpdateAt,
                    in: container,
                    debugDescription: "Date string does not match ISO8601 format."
                )
            }
            lastUpdateAt = date
        }
    }
}
