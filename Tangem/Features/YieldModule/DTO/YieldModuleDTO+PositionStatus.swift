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
        let supplyCap: BigUInt
        let userBalance: BigUInt
        let earnedYield: BigUInt
        let totalDeposited: BigUInt
        let moduleAddress: String
        let decimals: Int
        let chainId: Int
        let chain: String
        let maxFeeNative: Decimal
        let maxFeeUSD: Decimal
        let priority: Int
        let isEnabled: Bool
        let lastUpdatedAt: Date

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
            case supplyCap
            case userBalance
            case earnedYield
            case totalDeposited
            case moduleAddress

            case decimals
            case chainId
            case chain
            case maxFeeNative
            case maxFeeUSD
            case priority
            case isEnabled
            case lastUpdatedAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            tokenAddress = try container.decode(String.self, forKey: .tokenAddress)
            tokenSymbol = try container.decode(String.self, forKey: .tokenSymbol)
            tokenName = try container.decode(String.self, forKey: .tokenName)

            guard let apy = try container.decode(FlexibleDecimal.self, forKey: .apy).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .apy,
                    in: container,
                    debugDescription: "apy cannot be converted to Decimal"
                )
            }
            self.apy = apy

            guard let totalSupplied = BigUInt(try container.decode(String.self, forKey: .totalSupplied)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .totalSupplied,
                    in: container,
                    debugDescription: "totalSupplied cannot be converted to Decimal"
                )
            }
            self.totalSupplied = totalSupplied

            guard let totalBorrowed = BigUInt(try container.decode(String.self, forKey: .totalBorrowed)) else {
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

            guard let supplyCap = BigUInt(try container.decode(String.self, forKey: .supplyCap)) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .supplyCap,
                    in: container,
                    debugDescription: "supplyCap cannot be converted to BigUInt"
                )
            }
            self.supplyCap = supplyCap

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

            moduleAddress = try container.decode(String.self, forKey: .moduleAddress)
            decimals = try container.decode(Int.self, forKey: .decimals)
            chainId = try container.decode(Int.self, forKey: .chainId)
            chain = try container.decode(String.self, forKey: .chain)

            guard let maxFeeNative = try container.decode(
                FlexibleDecimal.self,
                forKey: .maxFeeNative
            ).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .maxFeeNative,
                    in: container,
                    debugDescription: "maxFeeNative cannot be converted to Decimal"
                )
            }
            self.maxFeeNative = maxFeeNative

            guard let maxFeeUSD = try container.decode(
                FlexibleDecimal.self,
                forKey: .maxFeeUSD
            ).wrappedValue else {
                throw DecodingError.dataCorruptedError(
                    forKey: .maxFeeUSD,
                    in: container,
                    debugDescription: "maxFeeUSD cannot be converted to Decimal"
                )
            }
            self.maxFeeUSD = maxFeeUSD

            priority = try container.decode(Int.self, forKey: .priority)

            isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
            lastUpdatedAt = try container.decode(Date.self, forKey: .lastUpdatedAt)
        }
    }
}
