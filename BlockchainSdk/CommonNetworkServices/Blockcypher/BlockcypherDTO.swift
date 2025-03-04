//
//  BlockcypherDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum BlockcypherDTO {
    enum Address {
        struct Response: Decodable {
            let address: String?
            let txrefs: [Txref]?
            let unconfirmedTxrefs: [Txref]?

            struct Txref: Decodable {
                // tx_hash
                let txHash: String
                // tx_output_n
                let txOutputN: Int
                // block_height
                let blockHeight: Int?
                let value: UInt64
            }
        }
    }

    enum TransactionInfo {
        struct Response: Decodable {
            let hash: String
            let blockHeight: Int
            let addresses: [String]
            let total: Decimal
            let fees: Decimal
            let size: Int64
            let confirmations: Int
            let confirmed: Date?
            let received: Date?
            let inputs: [Input]
            let outputs: [Output]

            struct Input: Decodable {
                let prevHash: String
                let outputIndex: Int
                let outputValue: UInt64
                let addresses: [String]
                let sequence: Int?
            }

            struct Output: Decodable {
                let value: Decimal // UInt64 can overflow with large ETH amounts
                let script: String?
                let addresses: [String]
            }
        }
    }

    enum Fee {
        struct Response: Decodable {
            let lowFeePerKb: UInt64
            let mediumFeePerKb: UInt64
            let highFeePerKb: UInt64
        }
    }

    enum Send {
        struct Response: Decodable {
            let tx: Tx

            struct Tx: Decodable {
                let hash: String
            }
        }
    }
}
