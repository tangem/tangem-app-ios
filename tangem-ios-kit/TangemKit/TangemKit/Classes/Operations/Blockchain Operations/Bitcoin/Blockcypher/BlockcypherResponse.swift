//
//  BlockcypherResponse.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

struct BlockcypherAddressResponse : Codable {
    let address: String?
    let balance: Int?
    let unconfirmed_balance: Int?
    let txrefs: [BlockcypherTxref]?
    let unconfirmed_txrefs: [BlockcypherTxref]?
    
}

struct BlockcypherTxref: Codable {
    let tx_hash: String?
    let tx_output_n: Int?
    let value: Int64?
    let confirmations: Int64?
    let script: String?
}

struct BlockcypherFeeResponse: Codable {
    let low_fee_per_kb: Int64?
    let medium_fee_per_kb: Int64?
    let high_fee_per_kb: Int64?
}

struct BlockcypherTx: Codable {
    let hex: String?
    let addresses: [String]?
}
