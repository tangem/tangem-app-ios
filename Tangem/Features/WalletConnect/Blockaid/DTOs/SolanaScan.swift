//
//  SolanaScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    enum SolanaScan {
        struct Request: Encodable {
            let encoding = "base64"
            let blockchain = "mainnet"

            let accountAddress: String?
            let options: [Option] = [.simulation, .validation]
            let metadata: Metadata

            let method: String
            let transactions: [String]

            struct Metadata: Encodable {
                let url: String
            }

            enum CodingKeys: String, CodingKey {
                case encoding
                case blockchain
                case accountAddress = "account_address"
                case options
                case metadata
                case method
                case transactions
            }
        }

        struct Response: Decodable {
            let result: Result

            struct Result: Decodable {
                let validation: Validation?
                let simulation: Simulation?
            }
        }

        struct Simulation: Decodable {
            let accountSummary: AccountSummary
            let error: String?
            let errorDetails: String?
        }

        struct AccountSummary: Decodable {
            let accountAssetsDiff: [AssetDiff]
        }

        struct AssetDiff: Decodable {
            let assetType: String
            let asset: Asset
            let `in`: TransactionDetail?
            let out: TransactionDetail?
        }
    }
}
