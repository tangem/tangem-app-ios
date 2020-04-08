//
//  BlockchairResponse.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

//struct BlockchairFeeResponse: Codable {
//    static let feePerByteKey = "suggested_transaction_fee_per_byte_sat"
//    let data: [String:String]
//}
//
//struct BlockchairSendResponse: Codable {
//    static let txHash = "transaction_hash"    
//    let data: [String:String]
//    let context: [String:String]
//}

struct BlockchairTransaction: Codable {
    let block_id: Int64?
}

struct BlockchairUtxo: Codable {
    let transaction_hash: String?
    let index: Int?
    let value: UInt64?
}
