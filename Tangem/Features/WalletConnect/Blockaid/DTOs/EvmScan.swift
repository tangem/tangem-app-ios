//
//  EvmScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    enum EvmScan {
        struct Request: Encodable {
            let chain: Chain
            let accountAddress: String?
            let data: Data
            let options: [Option] = [.simulation, .validation]
            let metadata: Metadata
            let block: String?

            struct Data: Encodable {
                let jsonrpc: String = "2.0"
                let params: [Params]
                let method: String
            }

            struct Metadata: Encodable {
                let domain: String
            }

            struct Params: Encodable {
                let from: String
                let to: String
                let data: String
                let value: String
            }

            enum Option: String, Encodable {
                case simulation
                case validation
            }
        }

        struct Response: Decodable {
            let validation: Validation?
            let simulation: Simulation?
            let events: [ScanEvent]?
            let block: String
            let chain: Chain
            let accountAddress: String

            struct Validation: Decodable {
                let status: Status
                let resultType: ResultType
                let description: String
                let reason: String
                let classification: String
                let features: [ScanFeature]
                let error: String?
            }            

            struct ScanFeature: Decodable {
                public var type: ResultType
                public var featureId: String
                public var description: String
                public var address: String?
            }

            struct ScanEvent: Decodable {
                public var emitterAddress: String
                public var emitterName: String?
                public var name: String?
                public var topics: [String]
                public var data: String
            }

            struct Asset: Decodable {
                let type: String
                let chainName: String?
                let decimals: Int
                let chainID: Int?
                let logoURL: String
                let name: String
                let symbol: String
            }

            struct ExposureDetail: Decodable {
                let value: Decimal
                let rawValue: String
            }

            struct SpenderDetail: Decodable {
                let summary: String
                let exposure: [ExposureDetail]
                let approval: String
                let expiration: Date
            }

            struct Exposure: Decodable {
                let assetType: String
                let asset: Asset
                let spenders: [String: SpenderDetail]
            }

            struct AccountSummary: Decodable {
                let assetsDiffs: [AssetDiff]
                let traces: [Trace]
                let exposures: [Exposure]
                let totalUSDExposure: [String: String]
            }

            struct Trace: Decodable {
                let type: String
                let exposed: ExposureDetail
                let traceType: String
                let owner: String
                let spender: String
                let asset: Asset
            }

            struct Simulation: Decodable {
                let status: Status
                let assetsDiffs: [String: [AssetDiff]]
                let exposures: [String: [Exposure]]
                let addressDetails: [String: AddressDetail]
                let accountSummary: AccountSummary
                let error: String?
                let errorDetails: String?
            }

            struct AddressDetail: Decodable {
                let nameTag: String
                let contractName: String?
            }

            struct AssetDiff: Decodable {
                struct BalanceChange: Decodable {
                    let usdPrice: Decimal
                    let value: Decimal
                    let rawValue: String
                }

                struct TransactionDetail: Decodable {
                    let usdPrice: Decimal
                    let summary: String
                    let value: Decimal
                    let rawValue: String
                }

                let assetType: String
                let asset: Asset
                let `in`: [TransactionDetail]
                let out: [TransactionDetail]
                let balanceChanges: [String: BalanceChange]
            }
        }
    }
}
