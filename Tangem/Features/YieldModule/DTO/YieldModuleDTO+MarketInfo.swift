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
        let supplyCap: String
        let isActive: Bool
        let decimals: Int
        let chainId: Int?
        let chain: String
        let maxFeeNative: Decimal
        let maxFeeUSD: Decimal

        private enum CodingKeys: String, CodingKey {
            case tokenAddress
            case tokenSymbol
            case tokenName
            case apy
            case supplyCap
            case isActive
            case decimals
            case chainId
            case chain
            case maxFeeNative
            case maxFeeUSD
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            tokenAddress = try container.decode(String.self, forKey: .tokenAddress)
            tokenSymbol = try container.decode(String.self, forKey: .tokenSymbol)
            tokenName = try container.decode(String.self, forKey: .tokenName)
            apy = try container.decode(Decimal.self, forKey: .apy)
            supplyCap = try container.decode(String.self, forKey: .supplyCap)
            isActive = try container.decode(Bool.self, forKey: .isActive)
            decimals = try container.decode(Int.self, forKey: .decimals)
            chainId = try container.decodeIfPresent(Int.self, forKey: .chainId)
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
        }
    }
}
