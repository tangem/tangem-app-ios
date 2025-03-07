//
//  UnspentOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct UnspentOutput {
    /// a.k.a `height`. The block which included the output. For unconfirmed `0`
    let blockId: Int
    /// The hash of transaction where the output was received
    /// DO NOT `reverse()` it  It should do a transaction builder
    let hash: Data
    /// The index of the output in transaction
    let index: Int
    /// The amount / value in the smallest denomination e.g. satoshi
    let amount: UInt64

    var isConfirmed: Bool { blockId > 0 }
    var txId: String { hash.hexString.lowercased().removeHexPrefix() }
}

struct ScriptUnspentOutput {
    let output: UnspentOutput

    /// LockedScript, ScriptPubKey, ScriptPubKey.hex
    let script: Data

    var blockId: Int { output.blockId }
    var hash: Data { output.hash }
    var index: Int { output.index }
    var amount: UInt64 { output.amount }
}
