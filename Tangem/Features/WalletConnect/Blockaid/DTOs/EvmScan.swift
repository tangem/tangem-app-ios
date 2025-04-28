//
//  EvmScan.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension BlockaidDTO {
    enum EvmScan {
        struct Request: Encodable {
            let accountAddress: String?
            let options: [Option] = [.simulation, .validation]
            let metadata: Metadata

            let chain: BlockaidDTO.Chain
            let data: Data
            let block: String?

            struct Data: Encodable {
                let jsonrpc: String = "2.0"
                let params: [Params]
                let method: String
            }

            struct Params: Encodable {
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
            let chain: Chain
            let accountAddress: String
        }

        struct Simulation: Decodable {
            let status: Status
            let assetsDiffs: [AssetDiff]?
            let exposures: [String: [Exposure]]?
            let addressDetails: [String: AddressDetail]?
            let accountSummary: AccountSummary?
            let error: String?
            let errorDetails: String?
        }

        struct AssetDiff: Decodable {
            let assetType: String
            let asset: Asset
            let `in`: [TransactionDetail]
            let out: [TransactionDetail]
        }

        struct AccountSummary: Decodable {
            let assetsDiffs: [AssetDiff]
            let traces: [Trace]
            let exposures: [Exposure]
        }
    }
}
