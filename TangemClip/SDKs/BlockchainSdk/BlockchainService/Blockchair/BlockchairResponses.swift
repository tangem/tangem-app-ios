//
//  BlockchairResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct BlockchairTransaction: Codable {
    let block_id: Int64?
}

struct BlockchairUtxo: Codable {
    let transaction_hash: String?
    let index: Int?
    let value: UInt64?
}

struct BlockchairToken: Codable {
    let address: String
    let name: String
    let symbol: String
    let decimals: Int
    let balanceApprox: Decimal
    let balance: String
    
    enum CodingKeys: String, CodingKey {
        case address = "token_address"
        case name = "token_name"
        case symbol = "token_symbol"
        case decimals = "token_decimals"
        case balanceApprox = "balance_approximate"
        case balance
    }
}
