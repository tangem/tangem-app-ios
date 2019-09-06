//
//  BtcFee.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

struct BtcFee {
    let minimalKb: Decimal
    let normalKb: Decimal
    let priorityKb: Decimal
}

struct BtcResponse : Codable {
    let balance: UInt64
    let unconfirmed_balance: Int?
    let txrefs: [BtcTx]
}

struct BtcTx: Codable {
    let tx_hash: String
    let tx_output_n: Int
    let value: UInt64
}
