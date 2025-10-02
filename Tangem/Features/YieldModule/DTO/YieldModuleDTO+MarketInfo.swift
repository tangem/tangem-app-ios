//
//  YieldModuleDTO+MarketInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

extension YieldModuleDTO.Response {
    struct MarketsInfo: Decodable {
        let tokens: [MarketInfo]
        let lastUpdatedAt: Date
    }

    struct MarketInfo: Decodable, Equatable {
        let tokenAddress: String
        let tokenSymbol: String
        let tokenName: String
        let apy: Decimal
        let totalSupplied: Decimal
        let totalBorrowed: Decimal
        let liquidityRate: BigUInt
        let borrowRate: BigUInt
        let utilizationRate: Decimal
        let isActive: Bool
        let ltv: Decimal
        let decimals: Int
        let liquidationThreshold: Decimal
        let maxNetworkFee: String? // temporary optional since backend isn't ready yet

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
            case decimals
            case maxNetworkFee
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            tokenAddress = try container.decode(String.self, forKey: .tokenAddress)
            tokenSymbol = try container.decode(String.self, forKey: .tokenSymbol)
            tokenName = try container.decode(String.self, forKey: .tokenName)
            apy = try container.decode(Decimal.self, forKey: .apy)
            decimals = try container.decode(Int.self, forKey: .decimals)

            guard let totalSupplied = try container.decode(FlexibleDecimal.self, forKey: .totalSupplied).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .totalSupplied,
                    in: container,
                    debugDescription: "totalSupplied cannot be converted to Decimal"
                )
            }
            self.totalSupplied = totalSupplied

            guard let totalBorrowed = try container.decode(FlexibleDecimal.self, forKey: .totalBorrowed).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .totalBorrowed,
                    in: container,
                    debugDescription: "totalBorrowed cannot be converted to Decimal"
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

            guard let utilizationRate = try container.decode(
                FlexibleDecimal.self,
                forKey: .utilizationRate
            ).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .utilizationRate,
                    in: container,
                    debugDescription: "utilizationRate cannot be converted to Decimal"
                )
            }
            self.utilizationRate = utilizationRate

            isActive = try container.decode(Bool.self, forKey: .isActive)

            guard let ltv = try container.decode(FlexibleDecimal.self, forKey: .ltv).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .ltv,
                    in: container,
                    debugDescription: "ltv cannot be converted to Decimal"
                )
            }
            self.ltv = ltv

            guard let liquidationThreshold = try container.decode(
                FlexibleDecimal.self,
                forKey: .liquidationThreshold
            ).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .liquidationThreshold,
                    in: container,
                    debugDescription: "liquidationThreshold cannot be converted to Decimal"
                )
            }
            self.liquidationThreshold = liquidationThreshold

            maxNetworkFee = try container.decodeIfPresent(String.self, forKey: .maxNetworkFee)
        }
    }
}
