//
//  UnspentOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct UnspentOutput: Hashable {
    /// a.k.a `height`. The block which included the output. For unconfirmed `0`
    let blockId: Int
    /// The hash/id of transaction where the output was received
    let txId: String
    /// The index of the output in transaction
    let index: Int
    /// The amount / value in the smallest denomination e.g. satoshi
    let amount: UInt64

    /// The hash of transaction where the output was received
    /// DO NOT `reverse()` it  It should do a transaction builder
    let hash: Data
    let isConfirmed: Bool

    init(blockId: Int, txId: String, index: Int, amount: UInt64) {
        self.blockId = blockId
        self.txId = txId
        self.index = index
        self.amount = amount

        hash = Data(hexString: txId)
        isConfirmed = blockId > 0
    }
}
