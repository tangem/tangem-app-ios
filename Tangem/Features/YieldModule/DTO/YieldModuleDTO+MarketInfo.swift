//
//  YieldModuleDTO+MarketInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension YieldModuleDTO.Response {
    struct MarketsInfo: Decodable {
        let markets: [MarketInfo]
        let lastUpdated: Date
    }

    struct MarketInfo: Decodable, Equatable {
        let tokenAddress: String
        let tokenSymbol: String
        let tokenName: String
        let apy: Decimal
        let totalSupplied: BigUInt
        let totalBorrowed: BigUInt
        let liquidityRate: BigUInt
        let borrowRate: BigUInt
        let utilizationRate: Decimal
        let isActive: Bool
        let ltv: Decimal
        let liquidationThreshold: Decimal

        enum CodingKeys: String, CodingKey {
            case tokenAddress
            case tokenSymbol
            case tokenName
            case apy
            case totalSupplied
            case totalBorrowed
            case liquidityRate
            case borrowRate
            case utilizationRate
            case isActive
            case ltv
            case liquidationThreshold
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            tokenAddress = try container.decode(String.self, forKey: .tokenAddress)
            tokenSymbol = try container.decode(String.self, forKey: .tokenSymbol)
            tokenName = try container.decode(String.self, forKey: .tokenName)
            apy = try container.decode(Decimal.self, forKey: .apy)

            guard let totalSupplied = BigUInt(try container.decode(String.self, forKey: .totalSupplied)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .totalSupplied,
                    in: container,
                    debugDescription: "totalSupplied cannot be converted to BigUInt"
                )
            }
            self.totalSupplied = totalSupplied

            guard let totalBorrowed = BigUInt(try container.decode(String.self, forKey: .totalBorrowed)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .totalBorrowed,
                    in: container,
                    debugDescription: "totalBorrowed cannot be converted to BigUInt"
                )
            }
            self.totalBorrowed = totalBorrowed

            guard let liquidityRate = BigUInt(try container.decode(String.self, forKey: .liquidityRate)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .liquidityRate,
                    in: container,
                    debugDescription: "liquidityRate cannot be converted to BigUInt"
                )
            }
            self.liquidityRate = liquidityRate

            guard let borrowRate = BigUInt(try container.decode(String.self, forKey: .borrowRate)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .borrowRate,
                    in: container,
                    debugDescription: "borrowRate cannot be converted to BigUInt"
                )
            }
            self.borrowRate = borrowRate

            utilizationRate = try container.decode(Decimal.self, forKey: .utilizationRate)
            isActive = try container.decode(Bool.self, forKey: .isActive)
            ltv = try container.decode(Decimal.self, forKey: .ltv)
            liquidationThreshold = try container.decode(Decimal.self, forKey: .liquidationThreshold)
        }
    }
}
