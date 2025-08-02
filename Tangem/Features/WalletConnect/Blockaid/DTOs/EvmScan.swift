//
//  EvmScan.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import ReownWalletKit

extension BlockaidDTO {
    enum EvmScan {
        struct Request: Encodable {
            let accountAddress: String?
            let options: [Option] = [.simulation, .validation]
            let metadata: Metadata

            let chain: BlockaidDTO.Chain
            let data: Data
            let block: String?

            struct Metadata: Encodable {
                let domain: String
            }

            struct Data: Encodable {
                let jsonrpc: String = "2.0"
                let params: [AnyCodable]
                let method: String
            }

            struct TransactionParams: Codable {
                let from: String
                let to: String
                let data: String
                let value: String
            }
        }

        struct Response: Decodable {
            let validation: Validation?
            let simulation: Simulation?
            let block: String
            let chain: String
            let accountAddress: String?
        }

        struct Simulation: Decodable {
            let status: Status
            let assetsDiffs: [String: [AssetDiff]]?
            let params: SimulationParams?
            let totalUsdDiff: [String: UsdDiff]?
            let exposures: [String: [Exposure]]?
            let totalUsdExposure: [String: [String: String]]?
            let addressDetails: [String: AddressDetail]?
            let accountSummary: AccountSummary?
        }

        struct SimulationParams: Decodable {
            let from: String
            let to: String
            let value: String
            let data: String
            let blockTag: String
            let chain: String
        }

        struct AssetDiff: Decodable {
            let assetType: String
            let asset: Asset
            let `in`: [TransactionDetail]
            let out: [TransactionDetail]
            let balanceChanges: BalanceChanges?
        }

        struct BalanceChanges: Decodable {
            let before: AssetBalance
            let after: AssetBalance
        }

        struct UsdDiff: Decodable {
            let `in`: String
            let out: String
            let total: String
        }

        struct AccountSummary: Decodable {
            let assetsDiffs: [AssetDiff]
            let traces: [Trace]
            let totalUsdDiff: UsdDiff?
            let exposures: [Exposure]
            let totalUsdExposure: [String: String]?
        }

        struct Trace: Decodable {
            let type: String
            let traceType: String
            let fromAddress: String?
            let toAddress: String?
            let asset: Asset
            let diff: DiffDetail?
        }

        struct AssetBalance: Decodable {
            @FlexibleDecimal var usdPrice: Decimal?
            @FlexibleDecimal var value: Decimal?
            let rawValue: String?

            private enum CodingKeys: String, CodingKey {
                case usdPrice = "usd_price"
                case value
                case rawValue = "raw_value"
            }

            public init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                _usdPrice = try c.decodeIfPresent(FlexibleDecimal.self, forKey: .usdPrice)
                    ?? FlexibleDecimal(wrappedValue: nil)
                _value = try c.decodeIfPresent(FlexibleDecimal.self, forKey: .value)
                    ?? FlexibleDecimal(wrappedValue: nil)
                rawValue = try c.decodeIfPresent(String.self, forKey: .rawValue)
            }
        }

        struct DiffDetail: Decodable {
            @FlexibleDecimal var usdPrice: Decimal?
            @FlexibleDecimal var value: Decimal?
            let rawValue: String?

            private enum CodingKeys: String, CodingKey {
                case usdPrice = "usd_price"
                case value
                case rawValue = "raw_value"
            }

            public init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                _usdPrice = try c.decodeIfPresent(FlexibleDecimal.self, forKey: .usdPrice)
                    ?? FlexibleDecimal(wrappedValue: nil)
                _value = try c.decodeIfPresent(FlexibleDecimal.self, forKey: .value)
                    ?? FlexibleDecimal(wrappedValue: nil)
                rawValue = try c.decodeIfPresent(String.self, forKey: .rawValue)
            }
        }
    }
}
