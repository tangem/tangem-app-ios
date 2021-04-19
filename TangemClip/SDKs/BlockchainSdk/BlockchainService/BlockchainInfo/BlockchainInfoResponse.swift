//
//  BlockchainInfoResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct BlockchainInfoAddressResponse: Codable {
    let final_balance: UInt64?
    let txs: [BlockchainInfoTransaction]?
	let n_tx: Int?
}

struct BlockchainInfoTransaction: Codable {
    let hash: String?
    let block_height: UInt64?
	/// Balance difference. Using to recognize outgoing transaction for signature count
	let result: Int64?
}

struct BlockchainInfoUnspentResponse: Codable  {
    let unspent_outputs: [BlockchainInfoUtxo]?
}

struct BlockchainInfoUtxo: Codable {
    let tx_hash_big_endian: String?
    let tx_output_n: Int?
    let value: UInt64?
    let script: String?
}
