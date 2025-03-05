//
//  BitcoreDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum BitcoreDTO {
    enum UTXO {
        struct Response: Decodable {
            let mintTxid: String
            let mintIndex: Int
            let mintHeight: Int?
            let value: UInt64
            let address: String
        }
    }

    enum TransactionInfo {
        struct Response: Decodable {
            let txid: String
            let network: String?
            let chain: String?
            let blockHeight: Int?
            let blockHash: String?
            // 2009-01-09T02:55:44.000Z
            let blockTime: Date?
            let blockTimeNormalized: String?
            let coinbase: Bool?
            let locktime: Int?
            let inputCount: Int?
            let outputCount: Int?
            let size: Int?
            let fee: Int
            let value: Int?
            let confirmations: Int?
        }
    }

    enum Coins {
        struct Response: Decodable {
            let inputs: [UTXO.Response]
            let outputs: [UTXO.Response]
        }
    }

    enum Send {
        struct Response: Decodable {
            let txid: String
        }
    }
}
